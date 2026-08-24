extends Node

## Autoload singleton (Project Settings -> Autoload, name it exactly
## "Economy") that tracks the player's money. Kept separate from
## SpiderContainer since money will matter beyond just spiders later
## (bigger containers, entry fees, etc).

signal money_changed(new_amount: int)

var money: int = 0

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

## Returns false (and spends nothing) if the player can't afford it.
func spend_money(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	money_changed.emit(money)
	return true