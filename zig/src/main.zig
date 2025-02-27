const std = @import("std");

const sqlite = @import("sqlite");
const zap = @import("zap");

const MAIN_DB = "zig.db";
const table = "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY AUTOINCREMENT,name REAL,timestamp INTEGER);";
const readq = "SELECT id, name, timestamp FROM test ORDER BY id DESC LIMIT 100;";
const writeq = "INSERT INTO test(name, timestamp) VALUES(?, ?);";

const SharedAllocator = struct {
    var allocator: std.mem.Allocator = undefined;
};

threadlocal var router: ?Router = null;
threadlocal var mainDB: ?sqlite.Db = null;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    SharedAllocator.allocator = allocator;
    {
        try initMainDBAndRouter();
        std.debug.print("SQLite version: {}\n", .{sqlite.c.SQLITE_VERSION_NUMBER});

        // RUN MIGRATION OF THE DB on Start up

        // we create a listener with our combined context
        // and pass it the initial handler: the user handler

        var listener: zap.HttpListener = zap.HttpListener.init(
            .{
                .on_request = on_request,
                .port = 3000,
                .log = false,
                .max_clients = 100000,
            },
        );
        //zap.enableDebugLog();

        listener.listen() catch |err| {
            std.debug.print("\nLISTEN ERROR: {any}\n", .{err});
            return;
        };

        std.debug.print("Visit me on http://127.0.0.1:3000\n", .{});

        const count = std.Thread.getCpuCount() catch |err| {
            std.debug.print("Error on getting CPU count: {}\n", .{err});
            return;
        };
        std.debug.print("CPU count: {}\n", .{count});
        // start worker threads
        zap.start(.{
            .threads = @intCast(count),
            .workers = 1,
        });
    }

    const has_leaked = gpa.detectLeaks();
    std.log.debug("Has leaked: {}\n", .{has_leaked});
}

pub fn initMainDBAndRouter() !void {
    if (mainDB == null) {
        std.debug.print("MainDB is initting for Thread ID: {}\n", .{std.Thread.getCurrentId()});
        mainDB = try sqlite.Db.init(.{
            .mode = sqlite.Db.Mode{ .File = MAIN_DB },
            .open_flags = .{
                .write = true,
                .create = true,
            },
            .threading_mode = .MultiThread,
        });

        _ = try mainDB.?.pragma(void, .{}, "journal_mode", "WAL");
        _ = try mainDB.?.pragma(void, .{}, "busy_timeout", "5000");

        try mainDB.?.exec(table, .{}, .{});
    }

    if (router == null) {
        std.debug.print("Router is initting for Thread ID: {}\n", .{std.Thread.getCurrentId()});
        router = .{};
        router.?.init() catch |err| {
            std.debug.print("Error on Router init occurred: {} Thread ID: {}\n", .{ err, std.Thread.getCurrentId() });
            router = null;
            return err;
        };
    }
}

pub fn on_request(r: zap.Request) void {
    //print thread and process id
    initMainDBAndRouter() catch |err| {
        std.debug.print("Error on Init occurred: {} Thread ID: {} \n", .{ err, std.Thread.getCurrentId() });
        r.setStatus(zap.StatusCode.internal_server_error);
        r.sendBody("500 Internal Server Error") catch return;
        return;
    };

    if (r.path) |path| {
        if (std.mem.eql(u8, path, "/read")) {
            router.?.read(r) catch |err| {
                std.debug.print("READ ERROR", .{});
                std.debug.print("Error occurred: {}\n", .{err});
                r.setStatus(zap.StatusCode.internal_server_error);
                r.sendBody("500 Internal Server Error") catch return;
                return;
            };
        } else if (std.mem.eql(u8, path, "/write")) {
            router.?.write(r) catch |err| {
                std.debug.print("Error occurred: {}\n", .{err});
                r.setStatus(zap.StatusCode.internal_server_error);
                r.sendBody("500 Internal Server Error") catch return;
                return;
            };
        } else {
            std.debug.print("Not found", .{});
        }
    }
    r.setStatus(zap.StatusCode.not_found);
    r.sendBody("404 Not Found") catch return;
}

const Router = struct {
    get: sqlite.Statement(.{}, sqlite.ParsedQuery(readq)) = undefined,
    put: sqlite.Statement(.{}, sqlite.ParsedQuery(writeq)) = undefined,

    const Self = @This();

    pub fn init(self: *Self) !void { // autofix
        self.get = try mainDB.?.prepare(readq);
        self.put = try mainDB.?.prepare(writeq);
    }

    pub fn read(self: *Self, r: zap.Request) !void {
        var arena = std.heap.ArenaAllocator.init(SharedAllocator.allocator);
        defer arena.deinit();

        self.get.reset();
        const rows = try self.get.all(ReadDBUser, arena.allocator(), .{}, .{});

        // Need to have at least 100 items
        var jsonbuf: [12800]u8 = undefined;

        if (zap.stringifyBuf(&jsonbuf, rows, .{})) |json| {
            try r.sendJson(json);
        }
    }

    pub fn write(self: *Self, r: zap.Request) !void {
        if (r.body) |body| {
            const maybe_user: ?std.json.Parsed(WriteEndpointUser) = std.json.parseFromSlice(WriteEndpointUser, SharedAllocator.allocator, body, .{}) catch null;
            if (maybe_user) |u| {
                defer u.deinit();
                self.put.reset();
                try self.put.exec(
                    .{},
                    .{ .name = u.value.name, .timestamp = std.time.timestamp() },
                );

                var buf: [256]u8 = undefined;
                const s = try std.fmt.bufPrint(&buf, "\"status\":\"OK\", \"name\": \"{s}\" ", .{u.value.name});

                try r.sendBody(s);
            }
        }
    }
};

const WriteEndpointUser = struct { name: []const u8 };
const WriteDBUSer = struct { name: []const u8, timestamp: i64 };
const ReadDBUser = struct { id: i64, name: []const u8, timestamp: i64 };

pub fn stringifyBuf(
    buffer: []u8,
    value: anytype,
    options: std.json.StringifyOptions,
) ?[]const u8 {
    var fba = std.heap.FixedBufferAllocator.init(buffer);
    var string = std.ArrayList(u8).init(fba.allocator());
    if (std.json.stringify(value, options, string.writer())) {
        return string.items;
    } else |_| { // error
        return null; // Todo, don't die silently here
    }
}
