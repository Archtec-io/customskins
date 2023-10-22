# CustomSkins
## API

### `customskins.register_item(item)`
Register a skin item. `item` is a table with item properties listed below.

### Item properties
`type`
Set the item type. Valid values are: "base", "shoes", "face", "legs", "bodyA", "bodyB", "hair", "misc"

`texture`
Set to the image file that will be used. If this property is omitted "blank.png" is used.

`preview_rotation`
A table containing properties x and y. x and y represent the x and y rotation of the item preview.

`sam`
If set to true the item will be default for male character.


### `customskins.show_formspec(player, active_tab, page_num)`
Show the skin configuration screen.
`player` is a player ObjectRef.
`active_tab` is the tab that will be displayed. This parameter is optional.
Can be one of: "base", "shoes", "face", "legs", "bodyA", "bodyB", "hair", "misc"

`page_num` The page number to display of there are multiple pages of items.
This parameter is optional. Must be a number. If it is not a valid page number the closest page number will be shown.

### `customskins.register_on_set_skin(func)`
Register a function to be called whenever a player skin changes.
The function will be given a player ObjectRef as a parameter.

### `customskins.save(player)`
Save player skin. `player` is a player ObjectRef.

### `customskins.update_player_skin(player)`
Update a player based on skin data in customskins.players.
`player` is a player ObjectRef.

### `customskins.players`
A table mapped by player ObjectRef containing tables holding the player's selected skin items and colors.
Only stores skin information for logged in users.

### `customskins.compile_skin(skin)`
`skin` is a table with skin item properties.
Returns an image string.
