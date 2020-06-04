breed [traders trader]

globals [
  DEBUG                ; turn on diagnostic messages?
  missions-completed   ; total number of missions completed
  num-trades           ; total number of trades made by all traders
  goals-reached        ; total number of goals reached (all products traded)
  deaths               ; number of traders who starved
  max-weight           ; max weight of supplies carried
  num-products         ; number of products being traded
  trade-radius         ; how close traders have to be to trade
  max-cost             ; max cost/risk of any patch
  infinity             ; a ridiculously big number needed for route planning
]

traders-own [
  home-patch           ; starting point
  goal-patch           ; market destination
  goal-reached         ; all of my product traded?
  mission-completed    ; returned home with goal reached
  route                ; route from home to goal
  sacks                ; sacks of products carried
  my-product           ; product provided
]

patches-own [
  cost        ; danger/difficulty here
  is-market   ; is this a market patch?
  cost2here   ; used for route planning
  unvisited   ; used for route planning
  predecessor ; used for route planning
]

;===========================
; initializers
;===========================

to init-model
  clear-all            ; get rid of everything from last run
  random-seed new-seed ; re-seed random number generator
  reset-ticks          ; reset clock (and plots)
  init-globals         ; initialize globals
  create-traders num-traders
  ask patches [init-patch]
  ask traders [init-trader]
end

to init-globals
  set DEBUG true
  set missions-completed 0
  set goals-reached 0
  set num-trades 0
  set deaths 0
  set max-weight 500
  set infinity 2 ^ 16
  set num-products 3
  set trade-radius 2
  set max-cost 10
end

to init-patch
  set is-market false ;random 100 < market-probability ; get rid of this, there should only be 1 - 5 markets ever
  set cost random max-cost
  set pcolor scale-color gray cost max-cost 0
  if is-market [
    set pcolor green
    set plabel "M"
    set cost 0
  ]
end

to init-trader
  setxy random-xcor random-ycor
  set shape "Person"

  set sacks n-values num-products [0]
  set my-product random num-products
  add-product my-product max-weight

  set color item my-product base-colors ; do something better with color

  set home-patch patch-here
  ask home-patch [
    set pcolor [color] of myself
    set cost 0
  ]
 ; set goal-patch one-of patches with [is-market and self != [home-patch] of myself]

  set goal-reached false
  set mission-completed false

 ; plan-route goal-patch

end

to plan-routes
  ask traders [
     set goal-patch one-of patches with [is-market and self != [home-patch] of myself]
     plan-route goal-patch
  ]
end


to set-market
  if mouse-down? [
    let selected-patch patch mouse-xcor mouse-ycor
    ask selected-patch [
      set is-market true
      set pcolor green
      set plabel "M"
      set cost 0
    ]
  ]
end


;===========================
; updaters
;===========================

to update-model
  if count traders = 0 [stop]
  ; update-globals
  ; ask patches [update-patch] useful if patch costs can change due to weather, plague, war, etc.
  ask traders [update-trader]
  tick ; advance clock
end

to update-trader
  set-mission-completed  ; mission completed?
  if mission-completed  [die] ; for now, else start a new mission?
  if get-supplies <= 0 [
      if DEBUG [show "Died"]
      set deaths deaths + 1
      die
   ]
   set-goal-reached ; goal reached?
   if patch-here != goal-patch or goal-reached [move]
   if not goal-reached [
    let neighbor one-of other traders in-radius trade-radius with [my-product != [my-product] of myself]
    if neighbor != nobody  [ trade neighbor ]
   ]
end

;===========================
; trader behaviors
;===========================

to move
  let loc position patch-here route
  ifelse goal-reached
  [
    if (loc > 0) [
      let dest item (loc - 1) route
      move-to dest
    ]
  ]
  [
    if loc < length route - 1 [
      let dest item (loc + 1) route
      pen-down
      move-to dest
      pen-up
    ]
  ]
  burn-supplies
end


to trade [neighbor]
  let nbr-product [my-product] of neighbor
  let nbr-amt [get-product nbr-product] of neighbor
  let my-amt get-product my-product
  let my-prod my-product
  let trade-amt min (list nbr-amt my-amt)
  ask neighbor [
    rem-product nbr-product trade-amt ; remove your spice
    add-product my-prod trade-amt     ; take my salt
  ]
  rem-product my-product trade-amt    ; remove my salt
  add-product nbr-product trade-amt   ; take your spice
  ;set-goal-reached
  set num-trades num-trades + 1
  if DEBUG [show "trade completed!"]
end

to burn-supplies
  let penalty [cost] of patch-here
  let sack my-product
  while [0 < get-supplies and 0 < penalty]
  [
   let amt get-product sack
   ifelse amt <= penalty
   [
     rem-product sack amt
     set penalty penalty - amt
   ]
   [
     rem-product sack penalty
     set penalty 0
   ]
    set sack (sack + 1) mod num-products
  ]
end

; Traders use Dijkstra's algorithm to plot
; a reasonable route to a destination
to plan-route [destination-patch]

  let all-patches patch-set patches  ; a hack, agents can't use patches to refer to all patches
  ask all-patches [set unvisited true set cost2here infinity set predecessor nobody]
  ask patch-here [set cost2here 0]
  while [[unvisited] of destination-patch] [
    let current-patch min-one-of (patches with [unvisited]) [cost2here]
    ask current-patch [set unvisited false]
    let nbrs ([neighbors] of current-patch) with [unvisited]
    ask nbrs [
      let sub-total cost + [cost2here] of current-patch
      if sub-total < cost2here [set cost2here sub-total set predecessor current-patch]
    ]
  ]
  set route (list destination-patch)
  let current-patch destination-patch
  while [current-patch != patch-here] [
    set current-patch [predecessor] of current-patch
    set route fput current-patch route
  ]
end


;===========================
; getters & setters
;===========================

to set-goal-reached
  let success ((get-product my-product) = 0) or (not trade-only and patch-here = goal-patch)
  if not goal-reached and success
  [
    if DEBUG [show "Goal reached!"]
    set goals-reached goals-reached + 1
    set goal-reached true
  ]
end

to set-mission-completed
  let success goal-reached and patch-here = home-patch
  if not mission-completed and success
  [
    if DEBUG [show "Mission completed!"]
    set missions-completed missions-completed + 1
    set mission-completed true
  ]
end

to-report get-supplies
  report reduce + sacks
end

to add-product [sack amt]
  set sacks replace-item sack sacks (amt + (item sack sacks))
end

to rem-product [sack amt]
  set sacks replace-item sack sacks ((item sack sacks) - amt)
end

to-report get-product [sack]
  report item sack sacks
end

; not used
to-report cost-to [destination]
  let result 0
  ifelse member? destination route [
     let i position patch-here route
     let j position destination route
     if j < i [
       let temp i
       set i j
       set j temp
     ]
     while [i <= j] [
       set result result + [cost] of item i route
       set i i + 1
     ]
    ]
  [
    set result infinity
  ]
  report result
end
@#$#@#$#@
GRAPHICS-WINDOW
244
10
785
552
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
45
38
157
71
setup
init-model
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
46
78
154
111
go
update-model
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
48
124
157
157
go-once
update-model
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
24
297
196
330
num-traders
num-traders
1
100
52.0
1
1
NIL
HORIZONTAL

MONITOR
853
101
971
146
missions completed
missions-completed
17
1
11

MONITOR
854
47
970
92
# of traders
count traders
17
1
11

MONITOR
854
156
973
201
goals reached
goals-reached
17
1
11

MONITOR
854
212
972
257
# of trades
num-trades
17
1
11

MONITOR
854
269
973
314
# of deaths
deaths
17
1
11

TEXTBOX
895
15
951
33
Data
11
0.0
1

TEXTBOX
73
15
122
33
Controls
11
0.0
1

SWITCH
47
370
160
403
trade-only
trade-only
0
1
-1000

BUTTON
46
178
161
211
NIL
set-market
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
56
234
151
267
NIL
plan-routes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

Salt Lab is a tool for modeling trading patterns in a barter economy of disperesed traders.

## HOW IT WORKS

A trader carries three sacks (or any number of sacks): sack-0 contains an amount of product-0 (salt), sack-1 contains an amount of product-1 (sugar), and sack-2 contains an amount of product-2 (spice). The sum of these amounts should never exceed the maximum weight the trader can carry (500 pounds). Initially, all sacks are empty except for the sack containing the product the trader wants to exchange. For example, a salt trader starts out with 500 pounds of salt in sack 0. His other sacks are empty.

A trader leaves home on a mission: to achieve his goal and return. The goal is to trade all of his surplus product for like amounts of needed products. The trader heads toward a market where he hopes to meet other traders. If the trader meets another trader at the market or enroute, a trade is made. For example, a salt trader with 500 pounds of salt meets a spice trader with 200 pounds of spice. The salt trader gives the spice trader 200 pounds of salt and takes 200 pounds of spice in exchange. The spice trader has now traded away all of his spice. He has accomplished his goal and can return home. But the salt trader still has 300 pounds of salt he needs to get rid of.

Unfortunately, traveling burns supplies (the total amount of products carried). When supplies become critically low, the trader should abort the goal and try to get home. If supplies become exhausted before reaching home, the trader dies.

Planning a route to a selected market is tricky. Each patch has an associated cost for traversing it. (High-cost patches are a darker shade of gray than low cost patches.) These patches might contain hostel tribes or difficult to traverse terrain. Traversing such patches increases the amount of supplies burned. The trader plans his route before departing. He uses Dijkstra's algorithm for computing the least costly route to market. 

## HOW TO USE IT

* The num-traders slider determines the number of traders.
* The market-probability slider determibnes the percentage of patches that are markets.
* The setup button creates the specified number of traders and positions them at random locations. It randomly designates the specified percentage of patches to be markets (green with label "M"), and it randomly assigns costs to each patch. (Darker patches have higher costs.)
* The go button repeatedly updates the traders until they are all dead (from starvation or success).
* the go-once button updates each trader once. 
* When the trade-only switch is on, the only way for traders to complete their goal is to trade away all of their surplus product with other traders. When off, a trader only needs to reach a market. THis is useful when there is only one trader.

## THINGS TO NOTICE


## THINGS TO TRY



## EXTENDING THE MODEL



## NETLOGO FEATURES



## RELATED MODELS

Models in the NetLogo Sugarscape suite include:

* Sugarscape 1 Immediate Growback
* Sugarscape 2 Constant Growback
* Sugarscape 3 Wealth Distribution

## CREDITS AND REFERENCES

Epstein, J. and Axtell, R. (1996). Growing Artificial Societies: Social Science from the Bottom Up.  Washington, D.C.: Brookings Institution Press.
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
