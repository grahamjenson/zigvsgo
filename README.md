# Test Golang SQLite API vs zig SQLite API

Just a quick test to see whats up with these different libraries

`/write` will write an item `{'name': "Graham Jenson", timestamp: <timestamp>}`
`/read` will read 100 items, serialize and return them

# Tests:


|              | **   read   ** | **   write   ** | **   random   ** |
|--------------|:--------------:|:---------------:|:----------------:|
| **go**       |                |                 |                  |
| **go InMemory**       |                |                 |                  |
| **zig safe** |                |                 |                  |
| **zig InMemory** |                |                 |                  |



# zig build -Doptimize=ReleaseSafe run

ab -c 100 -n 1000000 -p postdata.json http://127.0.0.1:3000/write
ab -c 100 -n 1000000 -p postdata.json http://127.0.0.1:3000/read


# WRITE
67% 12700kb

Document Path:          /write
Document Length:        42 bytes

Concurrency Level:      100
Time taken for tests:   59.632 seconds
Complete requests:      1000000
Failed requests:        0
Total transferred:      179000000 bytes
Total body sent:        168000000
HTML transferred:       42000000 bytes
Requests per second:    16769.54 [#/sec] (mean)
Time per request:       5.963 [ms] (mean)
Time per request:       0.060 [ms] (mean, across all concurrent requests)
Transfer rate:          2931.39 [Kbytes/sec] received
                        2751.25 kb/s sent
                        5682.65 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.2      0      45
Processing:     1    6  17.6      5    3360
Waiting:        1    6  17.6      5    3360
Total:          2    6  17.6      5    3360

Percentage of the requests served within a certain time (ms)
  50%      5
  66%      5
  75%      5
  80%      5
  90%      5
  95%      6
  98%      6
  99%     15
 100%   3360 (longest request)

# READ

500% 12416

Document Path:          /read
Document Length:        6302 bytes

Concurrency Level:      100
Time taken for tests:   46.732 seconds
Complete requests:      1000000
Failed requests:        8
   (Connect: 0, Receive: 0, Length: 8, Exceptions: 0)
Total transferred:      6472000000 bytes
Total body sent:        167000000
HTML transferred:       6302000000 bytes
Requests per second:    21398.46 [#/sec] (mean)
Time per request:       4.673 [ms] (mean)
Time per request:       0.047 [ms] (mean, across all concurrent requests)
Transfer rate:          135244.93 [Kbytes/sec] received
                        3489.79 kb/s sent
                        138734.72 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    2   3.0      2     147
Processing:     1    2  12.9      2    6224
Waiting:        1    2   3.5      2     148
Total:          2    4  13.3      4    6224

Percentage of the requests served within a certain time (ms)
  50%      4
  66%      4
  75%      4
  80%      4
  90%      4
  95%      4
  98%      5
  99%      5
 100%   6224 (longest request)


# Go

# WRITE
180% 65000

Document Path:          /write
Document Length:        44 bytes

Concurrency Level:      100
Time taken for tests:   61.580 seconds
Complete requests:      1000000
Failed requests:        0
Total transferred:      161000000 bytes
Total body sent:        168000000
HTML transferred:       44000000 bytes
Requests per second:    16239.05 [#/sec] (mean)
Time per request:       6.158 [ms] (mean)
Time per request:       0.062 [ms] (mean, across all concurrent requests)
Transfer rate:          2553.21 [Kbytes/sec] received
                        2664.22 kb/s sent
                        5217.43 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0      80
Processing:     0    6  52.5      0    3445
Waiting:        0    6  52.5      0    3445
Total:          0    6  52.5      0    3445

Percentage of the requests served within a certain time (ms)
  50%      0
  66%      0
  75%      0
  80%      1
  90%      3
  95%      9
  98%     60
  99%    121
 100%   3445 (longest request)


 # READ
 
 670% 71000

 Document Path:          /read
Document Length:        6303 bytes

Concurrency Level:      100
Time taken for tests:   64.643 seconds
Complete requests:      1000000
Failed requests:        0
Total transferred:      6400000000 bytes
Total body sent:        167000000
HTML transferred:       6303000000 bytes
Requests per second:    15469.68 [#/sec] (mean)
Time per request:       6.464 [ms] (mean)
Time per request:       0.065 [ms] (mean, across all concurrent requests)
Transfer rate:          96685.50 [Kbytes/sec] received
                        2522.89 kb/s sent
                        99208.38 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.7      0      93
Processing:     0    6   6.7      4     119
Waiting:        0    6   6.7      4     119
Total:          0    6   6.8      4     120

Percentage of the requests served within a certain time (ms)
  50%      4
  66%      7
  75%      9
  80%     10
  90%     14
  95%     19
  98%     24
  99%     31
 100%    120 (longest request)


