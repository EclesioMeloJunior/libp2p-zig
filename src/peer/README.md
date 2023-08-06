## multiaddr

Multiaddresses are parsed from left to right, but they should be interpreted from right to left.

Each component of a multiaddr wraps all the left components in its context.

For example, the multiaddr:

```
/dns4/example.com/tcp/1234/tls/ws/tls
```

is interpreted by taking the first `tls` component from the right and interpreting it as the libp2p security protocol to use for the connection, then the next componenent `ws` is

