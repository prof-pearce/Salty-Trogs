breed [traders trader]

traders-own
[
  good-consumed     ; what I eat
  good-produced     ; what I make
  good-held         ; what I hold
  storage-costs     ; list of storage costs for each type of good
  utility           ; lifetine utility
  ;marginal-utility  ; instantaneous utility of consuming
 ; production-cost   ; cost of producing
  partner           ; current trading partner
  is-speculative    ; will I trade my production good for a non-consumable good?
]

globals
[
   num-traders
   salt
   sugar
   spice
]


;===========================
; initializers
;===========================

to init-model
  clear-all            ; get rid of everything from last run
  random-seed new-seed ; re-seed random number generator
  reset-ticks          ; reset clock (and plots)
  init-globals         ; initialize globals

  create-traders num-traders / 3 [ init-trader salt ]
  create-traders num-traders / 3 [ init-trader sugar ]
  create-traders num-traders / 3 [ init-trader spice ]
  let circle-radius 10 ; for now
  layout-circle traders circle-radius
  ask patches [init-patch]
end

to init-globals
  set num-traders 30 ; for now
  set salt 0
  set sugar 1
  set spice 2
end

to init-patch
  set pcolor white
end

to init-trader [consumption-good]
  set good-consumed consumption-good
  set good-produced (good-consumed + 1) mod 3
  set good-held good-produced
  set utility 0
  set partner nobody
  set shape "Person"
  ; set strategies & color:
  ifelse good-consumed = salt
  [
    set color green
    set is-speculative salt-consumer-is-speculative
  ]
  [
    ifelse good-consumed = sugar
    [
      set color blue
      set is-speculative sugar-consumer-is-speculative
    ]
    [
      set color red
      set is-speculative spice-consumer-is-speculative
    ]
  ]
  ; for now assume utility, production cost, and storage cost are the same for all types:
  ;set production-cost .01
  ;set marginal-utility 2
  set storage-costs (list salt-storage-cost sugar-storage-cost spice-storage-cost)
end

;============================
; updaters
;============================

to update-model
  ;update-globals
  ask traders [update-trader]
  ask traders [set partner nobody]
  tick
  clear-links
  ;print distributions
end

to update-globals
  ask traders [set storage-costs (list salt-storage-cost sugar-storage-cost spice-storage-cost)]
end

to update-trader
  if partner = nobody
  [
    set partner one-of other traders with [partner = nobody and will-trade? myself]
    ifelse partner != nobody and will-trade? partner
    [
      ask partner [set partner myself]
      trade
    ]
    [
      set utility utility - item good-held storage-costs
    ]
  ]
end

to-report will-trade? [candidate]
  let candidate-good [good-held] of candidate
  ifelse candidate-good = good-consumed
  [
    report true
  ]
  [
     ifelse candidate-good = good-held
     [
       report false
     ]
     [
        report (speculate? and is-speculative) or (not speculate? and item candidate-good storage-costs < item good-held storage-costs)
        ;report is-speculative
     ]
  ]
end

to trade
  create-link-with partner
  let partner-good [good-held] of partner
  let old-good good-held
  set good-held partner-good
  update-utility
  ask partner [set good-held old-good update-utility]
end

to update-utility
  ifelse good-held = good-consumed
  [
    set good-held good-produced
    set utility utility + marginal-utility - production-cost - item good-held storage-costs
  ]
  [
    set utility utility - item good-held storage-costs
  ]
end


;=====================

to-report avg-utility [good]
  let total 0
  ask traders with [good-consumed = good] [set total total + utility]
  report 3 * total / max (list 1 num-traders)
end

; computes percentage of traders holding specified good
to-report probability [trader-type good]
  ifelse good = trader-type
  [
    report 0
  ]
  [
     let pop count traders with [good-consumed = trader-type and good-held = good]
     report pop / count traders
  ]
end

to-report distributions
  let i 0
 ; let j 0
  let result []
  while [i < 3]
  [
    let j 0
    while [j < 3]
    [
      ifelse i = j
      [
        set result lput 0 result
      ]
      [
        let n count traders with [good-produced = i and good-held = j]
        set result lput (n / num-traders) result
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  report result
end

@#$#@#$#@
GRAPHICS-WINDOW
314
10
751
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
22
13
88
46
set up
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
101
14
164
47
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

SWITCH
34
65
256
98
Salt-consumer-is-speculative
Salt-consumer-is-speculative
1
1
-1000

SWITCH
36
153
257
186
Spice-consumer-is-speculative
Spice-consumer-is-speculative
1
1
-1000

SWITCH
34
106
259
139
Sugar-consumer-is-speculative
Sugar-consumer-is-speculative
1
1
-1000

SLIDER
49
202
221
235
salt-storage-cost
salt-storage-cost
0
1
0.06
.01
1
NIL
HORIZONTAL

SLIDER
48
294
220
327
spice-storage-cost
spice-storage-cost
0
1
0.36
.01
1
NIL
HORIZONTAL

SLIDER
49
250
221
283
sugar-storage-cost
sugar-storage-cost
0
1
0.19
.01
1
NIL
HORIZONTAL

PLOT
780
30
1103
180
Avg Utilities
time
avg util
0.0
100.0
-10.0
100.0
true
false
"" ""
PENS
"salt-pen" 1.0 0 -13840069 true "" "plot avg-utility 0"
"sugar-pen" 1.0 0 -8990512 true "" "plot avg-utility 1"
"spice-pen" 1.0 0 -2674135 true "" "plot avg-utility 2"

SLIDER
49
342
221
375
marginal-utility
marginal-utility
0
10
1.0
.1
1
NIL
HORIZONTAL

SLIDER
48
394
220
427
production-cost
production-cost
0
1
0.02
.01
1
NIL
HORIZONTAL

MONITOR
856
226
913
271
sugar
probability 0 1
3
1
11

MONITOR
981
226
1038
271
spice
probability 0 2
3
1
11

TEXTBOX
888
204
1038
222
holdings of salt consumers
11
0.0
1

TEXTBOX
884
283
1034
301
holdings of sugar consumers
11
0.0
1

TEXTBOX
896
368
1046
386
holdings of spice consumers
11
0.0
1

MONITOR
852
312
909
357
salt
probability 1 0
3
1
11

MONITOR
980
308
1037
353
spice
probability 1 2
3
1
11

MONITOR
856
392
913
437
salt
probability 2 0
3
1
11

MONITOR
982
391
1039
436
sugar
probability 2 1
3
1
11

SWITCH
183
15
297
48
speculate?
speculate?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

A lab for exploring money evolution based on Kiyotaki & Wright's "On Money as a Medium of Exchange", 1989. (K&W)

## HOW IT WORKS

A market is populated by traders. There are three types of goods: salt, sugar, and spice.
There are equal numbers of three types of traders: salt consumers, sugar consumers, and spice consumers.

Salt consumers produce sugar. Sugar consumers produce spice, and spice consumers produce salt. 

A trader holds a unit of one good. (This will always be different from the consumed good, because a consumed good will be consumed immeditely and replaced by the produced good.)

During an update cycle traders are paired so that A is willing to trade with B and vice-versa, where:

* A is willing to trade with B is B holds the good consumed by A. 
* A is unwilling to trade with B if the good held by B is the same good held by A.
* In all other cases A trades with B if A is speculative or if the storage cost is less (depending on the model settings).

If A acquires his consumption good in a trade, he consumes it and stores a new unit of his production good. His updated utility will be:

`utility = utility + marginal-utility - production-cost - storage-cost`

If A acquires a non-consumable good or if no trade happens, then:

`utility = utility - storage-cost`

Similarly for B.

## HOW TO USE IT

Trading strategies: Each type of trader is either speculative (will trade for a non-consumable) or not. 

Speculate?: This switch controls the strategy used when trading for a non-consumable. When off, only storage costs are considered. When on, only the trading strategy is used.

Storage costs: Each type of good has a storage cost. In K&W the storage cost can differ for each type of trader. They also assume 0 < salt-storage-cost < sugar-storage-cost < spice-storage-cost < 1.

Marginal utility: the utility of consuming one unit of a consumable good. In K&W this also varies from one type of consumer to another.

Production cost: The cost of producting one unit of a good. In K&W this also varies from one type of consumer to another.

Avg Utilities: The average lifetime utility for each type of consumer. 

Holdings: percent of each type of consumer holding each type of good. Note that no consumer holds his own consumption good because he consumes it immediately.


## THINGS TO NOTICE

Assume 0 < salt-storage-cost < sugar-storage-cost < spice-storage-cost < 1 (the default settings).

Initially, each trader holds a unit of his production good. Salt consumer A holds sugar and a spice consumer B holds salt. A will trade with B, but B will only trade with A if he speculates that he can trade A's lump of sugar for a lump of spice later. So if no one speculates, no trading happens. Each trader hangs on to his production good forever.

K&W find two Nash equilibria: fundamental and speculative. In the fundamental equilibrium traders will only trade for non-consumables based on storage costs. So a spice consumer will always trade sugar for salt, a salt consumer will usually trade spice for sugar (depending on the storage costs), and a sugar consumer will always trade spice for salt. In other words, only sugar consumers will trade their production good for a non-consumable. Only sugar consumers will speculate. 


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
