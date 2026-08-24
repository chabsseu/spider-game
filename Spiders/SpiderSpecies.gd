extends Resource
class_name SpiderSpecies

## Lightweight identity data for a spider species. Create these as
## .tres files (right-click in FileSystem -> New Resource -> SpiderSpecies)
## — one per species you want in the game. This is deliberately minimal
## for now (no battle stats yet) since the battle system is still being
## redesigned; this just gives caught spiders a real identity instead of
## a bare difficulty number.

@export var species_name: String = "Unknown Spider"
@export var difficulty: float = 0.3 ## 0.0 (common/easy) - 1.0 (rare/hard). Feeds the catch minigame.
@export var sell_price: int = 10 ## how much selling one of these to the trader earns
@export var buy_price: int = 20 ## how much buying one of these from the trader costs
@export var description: String = ""

## Optional: once you have real art, assign a texture here and swap
## WebSpot's placeholder _draw() for a Sprite2D using this.
@export var icon: Texture2D