globals[
  playernb
]

breed[places place]
breed[players player]

places-own[
  nextnbfishes
  nbfishes
  harbour
  name
]

players-own[
  boat-type
  stock-fish
  capital
  harvest-level
  last-catch
  history-catch
  history-moves
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       SETUP                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  stop-inspecting-dead-agents
  set-default-shape places "circle"
  ask patches [set pcolor sky]
  let posxlist [ 1 3 0 2 4 1 3]
  let posylist [ 0 0 2 2 2 4 4]
  let collist [ violet red green yellow black]

  let i 0
  create-players nb-player[
    set shape "boat"
    set boat-type "simple"
    setxy 0 2 ;(0 + (random-float 0.8) - 0.4) (2 + (random-float 0.8) - 0.4)
    set color item i collist
    set i i + 1
    set capital 2
    set history-catch (list)
    set history-moves (list)
    set harvest-level 1; random-float 1 ;;TODO: initialize harvest-level with more complexity?
  ]


  set i 0
  create-places 7 [
    set nbfishes init-fishes
    set color blue
    set size 1
    setxy item i posxlist item i posylist
    set name ifelse-value (i = 0)["A"][ifelse-value (i = 1)["B"][ifelse-value (i = 2)["H"][ifelse-value (i = 3)["C"][ifelse-value (i = 4)["D"][ifelse-value (i = 5)["E"]["F"]]]]]]
    set i i + 1
    set harbour false
    set label (word "place " name " with " nbfishes " fishes")
  ]
  ask patch 0 2 [
    ask places-here[
      set harbour true
      set color cyan
    ]
  ]
  ask places [
    ask other places with [distance myself < 3] [
      create-link-with myself [set color blue]
    ]
  ]

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       PLAY for interactive players     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to play
  if ticks > 15 [stop]
  ask players [inspect self]
  set playernb 0
  while [playernb < nb-player ][
    let currentplayer (player playernb)
    let move? user-yes-or-no? (word "Time for player " playernb " to play." " Do you want to move?")
    ifelse move? and [capital] of currentplayer = 0 [
      user-message "You do not have the capital to move"
    ][
      if move? [
        ask currentplayer [
          let potential-places one-of [[name] of link-neighbors] of places-here
          if boat-type = "speedy" [set potential-places ["A" "B" "C" "D" "E" "F" "H"]]
          let nextplace user-one-of "choose your next location, place: " potential-places ;
          let cost 1
          if not member? nextplace one-of [[name] of link-neighbors] of places-here[set cost 2]
          move-to one-of places with [name = nextplace]
          set capital capital - cost
          ;set history-moves lput nextplace history-moves
        ]
      ]
    ]
    let fish? user-yes-or-no? (word "Player " playernb " , do you want to fish?")
    if fish? [
      let available first [[nbfishes] of places-here] of currentplayer
      let nbcaught user-one-of "how many fish do you take: " range (available + 1)
      ask currentplayer[
        if stock-fish + nbcaught > stock boat-type [
          set nbcaught stock boat-type - stock-fish
          user-message (word "You caught only " nbcaught " because your boat is full")
        ]
        set stock-fish stock-fish + nbcaught
        set last-catch nbcaught
        ;set history-catch lput last-catch history-catch
        ask places-here [
          set nbfishes nbfishes - nbcaught
          set label (word "place " name " with " nbfishes " fishes")
        ]
      ]
    ]
    ask currentplayer [
      if (one-of [harbour] of places-here) and stock-fish > 0[
        let sell? user-yes-or-no? (word "Player " playernb " , do you want to sell your fish?")
        if sell? [
          set capital capital + stock-fish
          set stock-fish 0
        ]
      ]
      if capital >= 12 and (one-of [harbour] of places-here) and boat-type = "simple"[
        let newboat-type user-one-of (word "Player " playernb " , do you want to buy a boat?") ["none" "fridge" "speedy"]
        if newboat-type != "none" [
          set boat-type newboat-type
          set capital capital - 10
          if boat-type = "fridge" [
            set size 2
          ]
          if boat-type = "speedy"
          [
            set shape "boat 3"
          ]
        ]
      ]

      set history-moves lput one-of ([name] of places-here) history-moves
      ifelse fish?
      [set history-catch lput last-catch history-catch]
      [set history-catch lput 0 history-catch]
    ]
    set playernb playernb + 1
  ]
  ask players [stop-inspecting self]
  output-show (word "End of turn " ticks ". Please wait... Neptune is regenerating the fish...")
  wait timers
  restock-fishes
  tick
end

to end-of-play
  if ticks > 15[
    let nbfi sum [nbfishes] of places
    let nbcap sum [capital] of players
    if (any? players with [boat-type != "simple"] ) [set nbcap nbcap + (count players with [boat-type != "simple"]) * 10]
    let caughttot sum [sum history-catch] of players
    let result ifelse-value (nbfi >= 20 and caughttot > (nb-player * 50 / 3 ) and nbcap > 20)["won!"]["lost..."]
    output-show (word "End of game, there are still " nbfi " fishes in the world, you caught "caughttot " and you capitalized " nbcap " ... ")
    output-show (word "So, you " result)
    if result = "won!" [
      let winner [who] of max-one-of players [capital]
      output-show (word "... in this winning game, the most efficient player is player " winner)
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       GO    for simulations (TODO)     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;if ticks > 15 [stop]
  player-behaviors
  restock-fishes
  tick
end


to restock-fishes
  ask places [set nextnbfishes nbfishes]
  ask places
  [
    if nbfishes >= 2 [
     ifelse nbfishes >= 5[
       ;envoyer à voisin
        let my-link link-neighbors with [nbfishes < 5]
        ask my-link [
          set nextnbfishes nextnbfishes + 1
        ]
      ]
      [
       set nextnbfishes nextnbfishes + 1
      ]
    ]
  ]
  ask places [
    set nbfishes min (list nextnbfishes 5)
    set label (word "place " name " with " nbfishes " fishes")
  ]
end

to player-behaviors
  player-moving
  player-fishing
  player-selling
end

to player-moving
end

to player-fishing
  ask players[
    set last-catch 0
  ;two extreme strategies for now:
    let myplace-nbfishes [nbfishes] of one-of places-here
    if myplace-nbfishes > 0[
      ifelse harvest-level > 0.5[
        ;1) harvest all
        let possible-stock stock boat-type - stock-fish
        if possible-stock > 0[
          let possible-catch min (list myplace-nbfishes possible-stock) ;harvest all
          set stock-fish stock-fish + possible-catch
          ask places-here[
            set nbfishes nbfishes - possible-catch
          ]
          set last-catch possible-catch
        ]
      ]
      ;2) always leave 2
      [

      ]
    ]
    set history-catch lput last-catch history-catch
  ]
end


to player-selling
  ask players[
    if stock-fish > 0 and any? places-here with [harbour][
      set capital capital + stock-fish
      set stock-fish 0
    ]
  ]
end

to-report stock [b-type]
  let reportv 5
  if(b-type = "fridge")[
    set reportv 20
  ]
  report reportv
end
@#$#@#$#@
GRAPHICS-WINDOW
302
75
782
556
-1
-1
94.4
1
10
1
1
1
0
0
0
1
0
4
0
4
0
0
1
ticks
30.0

SLIDER
116
95
288
128
init-fishes
init-fishes
0
5
2.0
1
1
NIL
HORIZONTAL

BUTTON
116
135
171
168
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
308
13
826
72
Nep-Tune     -    The Game
40
105.0
1

SLIDER
116
58
288
91
nb-player
nb-player
0
5
2.0
1
1
NIL
HORIZONTAL

PLOT
801
76
1184
335
Caught Fishes
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "ask players[\n set-plot-pen-color color\n plotxy ticks last-catch\n ]"
PENS
"default" 1.0 2 -16777216 true "" ""

BUTTON
232
135
287
168
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
174
136
229
169
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
804
346
1181
610
capital evolution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "ask players[\n set-plot-pen-color color\n plotxy ticks capital\n ]"
PENS
"default" 1.0 2 -16777216 true "" ""

TEXTBOX
12
204
70
234
Player:
15
0.0
1

MONITOR
63
193
125
238
NIL
playernb
0
1
11

BUTTON
46
134
109
167
NIL
play
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
140
174
303
219
stock of fish of current player
[stock-fish] of (player playernb)
0
1
11

MONITOR
141
222
303
267
capital of current player
[capital] of (player playernb)
0
1
11

PLOT
8
343
298
557
Fish population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [nbfishes] of places"

OUTPUT
7
563
782
635
11

BUTTON
33
248
129
281
NIL
end-of-play
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
95
104
128
timers
timers
0
5
0.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat 3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
BUTTON
14
10
77
43
fish
NIL
NIL
1
T
OBSERVER
NIL
NIL

SLIDER
87
10
186
43
to-fish
to-fish
0.0
5.0
0
1.0
1
NIL
HORIZONTAL

BUTTON
14
54
77
87
move
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
15
97
78
130
sell
NIL
NIL
1
T
OBSERVER
NIL
NIL

BUTTON
16
136
98
169
buy-boat
NIL
NIL
1
T
OBSERVER
NIL
NIL

CHOOSER
107
136
245
181
boat-to-buy
boat-to-buy
\"cargo\" \"speed-boat\"
0

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
