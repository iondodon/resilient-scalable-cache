Resilient & Scalable Key-Value Cache
Introducing a fault-tolerant, highly scalable key-value cache system, similar to Redis, built with Elixir. Elixir's error recovery capabilities allow the application to restart without losing state upon encountering errors.

[![Watch the demo](https://img.youtube.com/vi/J-ny69sOOwM/maxresdefault.jpg)](https://youtu.be/J-ny69sOOwM)

Connect via telnet (telnet localhost 6666) to execute the following supported commands:

- SET: Stores or updates a value for a given key. Format: SET key value.
- SETNX: Sets a value for a key only if it doesn't exist. Format: SETNX key value.
- GET: Retrieves the value for a given key. Format: GET key.
- MGET: Retrieves values for multiple keys. Format: MGET key1 key2 ... keyN.
- DEL: Deletes a single key-value pair or multiple pairs. Format: DEL key or DEL key1 key2 ... keyN.
- INCR: Increments an integer value for a given key by 1. Format: INCR key.
- LPUSH: Adds values to the left end of a list at a given key. Format: LPUSH key value1 value2 ... valueN.
- RPOP: Removes and returns the rightmost element of a list at a given key. Format: RPOP key.
- LLEN: Returns the length of a list at a given key. Format: LLEN key.
- LREM: Removes the first occurrence of a value from a list at a given key. Format: LREM key value.
- RPOPLPUSH: Moves the rightmost element from a list at key1 to the left end of a list at key2. Format: RPOPLPUSH key1 key2.
- EXPIRE: Sets an expiration time for a key, which is removed after the specified seconds. Format: EXPIRE key seconds.
- TTL: Returns the remaining time-to-live (in seconds) for a key. Format: TTL key.

The cache employs a master-slave architecture, with one master process and multiple slaves. Slaves can be created on-demand after the master starts. The master listens for incoming connections from slaves on port 6667, while port 6666 is used for client requests (e.g., telnet).

The master handles coordination and request redirection, while slaves execute commands and store data. This design enables horizontal scaling by adding more slaves.

Data is distributed across slaves using a hashing technique. For instance, executing `SET name Ion` may store the key-value pair on slave1, while `SET location Chisinau`could be stored on slave2, depending on their hash values. The cache uses `polynomial rolling hashing` to generate numerical hashes for keys and slave names.

To determine which slave executes a command, the master iterates through the slave hashes and selects the first slave with a hash greater than the key's hash.

Multiple replicas of the same slave ensure data availability. For example, there may be two replicas of slave1 (cache-slave1-replica1 and cache-slave1-replica2). If one replica fails, the other maintains the same state, allowing a new replica to replace the failed one.
