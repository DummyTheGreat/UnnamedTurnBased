extends Node

func EquationOfLine(firstPosition: Vector2, secondPosition: Vector2, scale: float) -> Vector2:
	return Vector2(
		firstPosition.x + scale * (secondPosition.x - firstPosition.x),
		firstPosition.y + scale * (secondPosition.y - firstPosition.y)
	)
	
