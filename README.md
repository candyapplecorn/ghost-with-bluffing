# ghost-with-bluffing
the word game ghost, with optional bluffing

### Directions

[https://en.wikipedia.org/wiki/Ghost_(game)](https://en.wikipedia.org/wiki/Ghost_(game))

Wikipedia's directions didn't make sense to me, but this site's directions did:

[http://www.grandparents.com/grandkids/activities-games-and-crafts/ghost](http://www.grandparents.com/grandkids/activities-games-and-crafts/ghost)

### Options
There's really only one option: turning bluffing on. In real life, bluffing is allowed, so I figured it should be implemented in the program too. It's off by default; the game is simpler and takes less time that way.

### Multiplayer
Multiplayer is forced; there is no maximum number of players, but the minimum is two.

### todo
It'd be neat if I could hook this up to a chat program's API, such as Discord. Then I could make a bot that facilitates Ghost games on Discord servers. I don't know of a Discord API in Ruby, so am not sure how to do that. I wonder - could I redirect the output from stdout to a socket? And the input as well? 
