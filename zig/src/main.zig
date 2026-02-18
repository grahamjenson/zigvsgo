const std = @import("std");

const httpz = @import("httpz");
const sqlite = @import("sqlite");

const MAIN_DB = "zig.db";
const table = "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY AUTOINCREMENT,name REAL,timestamp INTEGER);";
const read_query = "SELECT id, name, timestamp FROM test ORDER BY id DESC LIMIT 100;";
const write_query = "INSERT INTO test(name, timestamp) VALUES(?, ?);";

var allocator: std.mem.Allocator = undefined;

const WriteEndpointUser = struct { name: []const u8 };
const ReadDBUser = struct { id: i64, name: []const u8, timestamp: i64 };

const App = struct {
    mainDB: ?sqlite.Db,
    get: sqlite.Statement(.{}, sqlite.ParsedQuery(read_query)),
    put: sqlite.Statement(.{}, sqlite.ParsedQuery(write_query)),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const gpaallocator = gpa.allocator();
    allocator = gpaallocator;
    {
        var app = try initApp();
        std.debug.print("SQLite version: {}\n", .{sqlite.c.SQLITE_VERSION_NUMBER});

        var server = try httpz.Server(*App).init(allocator, .{ .address = .localhost(3000) }, &app);
        defer {
            // clean shutdown, finishes serving any live request
            server.stop();
            server.deinit();
        }

        var router = try server.router(.{});
        router.get("/read", read, .{});
        router.post("/write", write, .{});

        std.debug.print("Visit me on http://127.0.0.1:3000\n", .{});
        try server.listen();
    }

    const has_leaked = gpa.detectLeaks();
    std.log.debug("Has leaked: {}\n", .{has_leaked});
}

pub fn initApp() !App {
    std.debug.print("MainDB is initting for Thread ID: {}\n", .{std.Thread.getCurrentId()});
    var mainDB = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = MAIN_DB },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });

    _ = try mainDB.pragma(void, .{}, "journal_mode", "WAL");
    _ = try mainDB.pragma(void, .{}, "busy_timeout", "5000");

    try mainDB.exec(table, .{}, .{});

    const get = try mainDB.prepare(read_query);
    const put = try mainDB.prepare(write_query);

    return .{
        .mainDB = mainDB,
        .get = get,
        .put = put,
    };
}

fn read(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = req; // autofix
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    app.get.reset();
    const rows = try app.get.all(ReadDBUser, arena.allocator(), .{}, .{});

    try res.json(rows, .{});
}

const User = struct {
    name: []const u8,
};

fn write(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try req.json(User)) |user| {
        app.put.reset();
        try app.put.exec(
            .{},
            .{ .name = user.name, .timestamp = std.time.timestamp() },
        );

        try res.json(.{ .name = user.name, .timestamp = std.time.timestamp() }, .{});
    }
}
