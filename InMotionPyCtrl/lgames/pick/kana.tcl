# hiragana comes first in the numerical order, so it should here too.
set ganabeg 0x3041
set ganaend 0x309e

set kanabeg 0x30a1
set kanaend 0x30fe

# entire hiragana section of code page

set ganastr ""
for {set i $ganabeg} {$i <= $ganaend} {incr i} {
append ganastr [format "%c" $i]
if {($i % 5) == 0} {append ganastr "\n"}
}

# entire katakana section of code page

set kanastr ""
for {set i $kanabeg} {$i <= $kanaend} {incr i} {
append kanastr [format "%c" $i]
if {($i % 5) == 0} {append kanastr "\n"}
}

# richard suchenwirth's mappings from romaji to katakana and hiragana

# (i had mistakenly swapped gana and kana in version 1,
# before our code distinguished between them.)

set gana {
cha \u3061\u3083 chu \u3061\u3085 cho \u3061\u3087
sha \u3057\u3083 shu \u3057\u3085 sho \u3057\u3087
kya \u304d\u3083 kyu \u304d\u3085 kyo \u304d\u3087
rya \u308a\u3083 ryu \u308a\u3085 ryo \u308a\u3087
pya \u3074\u3083 pyu \u3074\u3085 pyo \u3074\u3087
ka \u304b ga \u304c ki \u304d gi \u304e ku \u304f gu \u3050 ke \u3051 ge \u3052 ko \u3053 go \u3054
sa \u3055 za \u3056 shi \u3057 ji \u3058 su \u3059 zu \u305a se \u305b ze \u305c so \u305d zo \u305e
ta \u305f da \u3060 chi \u3061 di \u3062 tsu \u3064 dsu \u3065 te \u3066 de \u3067 to \u3068 do \u3069
na \u306a ni \u306b nu \u306c ne \u306d no \u306e
ha \u306f ba \u3070 pa \u3071 hi \u3072 bi \u3073 pi \u3074 fu \u3075 bu \u3076 pu \u3077 he \u3078 be \u3079 pe \u307a ho \u307b bo \u307c po \u307d
ma \u307e mi \u307f mu \u3080 me \u3081 mo \u3082
ya \u3084 yu \u3086 yo \u3088
ra \u3089 ri \u308a ru \u308b re \u308c ro \u308d
wa \u308f wo \u3092 n \u3093
a \u3042 i \u3044 u \u3046 e \u3048 o \u304a
k \u3063 p \u3063 t \u3063
}

set kana {
cha \u3061\u30e3 chu \u3061\u30e5 cho \u3061\u30e7 sha \u30b7\u30e3
shu \u30b7\u30e5 sho \u30b7\u30e7
kya \u30ad\u30e3 kyu \u30ad\u30e5 kyo \u30ad\u30e7
rya \u30ea\u30e3 ryu \u30ea\u30e5 ryo \u30ea\u30e7
pya \u30d4\u30e3 pyu \u30d4\u30e5 pyo \u30d4\u30e7
ka \u30ab ga \u30ac ki \u30ad gi \u30ae ku \u30af gu  \u30b0 ke \u30b1 ge \u30b2 ko \u30b3 go \u30b4
sa \u30b5 za \u30b6 shi \u30b7 ji \u30b8 su \u30b9 zu \u30ba se \u30bb ze \u30bc so \u30bd zo \u30be
ta \u30bf da \u30c0 chi \u30c1 di \u30c2 tsu \u30c4 dsu \u30c5 te \u30c6 de \u30c7 to \u30c8 do \u30c9
na \u30ca ni \u30cb nu \u30cc ne \u30cd no \u30ce ha \u30cf
ba \u30d0 pa \u30d1 hi \u30d2 bi \u30d3 pi \u30d4 fu \u30d5 bu \u30d6 pu \u30d7 he \u30d8 be \u30d9 pe \u30da ho \u30db bo \u30dc po \u30dd
ma \u30de mi \u30df mu \u30e0 me \u30e1 mo \u30e2
ya \u30e4 yu \u30e6 yo \u30e8
ra \u30e9 ri \u30ea ru \u30eb re \u30ec ro \u30ed
wa \u30ef wo \u30f2 n \u30f3
a \u30a2 i \u30a4 u \u30a6 e \u30a8 o \u30aa
k \u30c3 p \u30c3 t \u30c3 - \u30fc
}

# the nice square aiueo part of the alphabet.

# i willfully leave out he,
# because the kana and gana look the same.
# ha hi fu he ho
set mini_kana {
    a i u e o
    ka ki ku ke ko
    sa shi su se so
    ta chi tsu te to
    na ni nu ne no
    ha hi fu fu ho
    ma mi mu me mo
}

array set gana_array $gana
array set kana_array $kana
set i 0
set ministr ""
foreach {name} $mini_kana {
    append ministr "$name:$gana_array($name):$kana_array($name)|"
    if {($i % 5) == 4} {append ministr "\n"}
    incr i
}

proc doputs {} {
	global kanastr ganastr ministr

	puts hiragana
	puts $ganastr
	puts ""

	puts katakana
	puts $kanastr
	puts ""

	puts ""
	puts "romaji:hiragana:katakana (incomplete)"

	puts $ministr
	puts "..."
}

# doputs
