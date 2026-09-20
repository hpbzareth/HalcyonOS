#!/bin/bash
device_code=$1
case $device_code in
	#13 13Pro 13Ultra K60Pro MIXFold 12TB 14Ultra
	fuxi | nuwa | ishtar | socrates | babylon | marble | aurora | dew | garnet | vermeer) size=9663676416;;
	#Xiaomi 15 Pro/Ultra Redmi Turbo 4 Pro
	haotian | xuanyuan | onyx | miro | klimt | dada | yudi | rodin | zorn | sheng | luming) size=11811160064;;
	#Xiaomi Mix Fold 4
	myron) size=14495514624;;
	#Xiaomi 17 Series
	annibale | pudding | popsicle | pandora) size=13421772800;;
	#Xiaomi 17 Ultra
	nezha) size=15300820992;;
	#Redmi Note 12 5G
	sunstone) size=9122611200;;
	#Xiaomi 14 , 14 Pro
	houji | shennong) size=8321499136;;
	#Redmi 12R
	sky) size=6979321856;;
	#Redmi Note 12/13 13C
	tapas | topaz | sapphire | sapphiren | gale) size=7516192768;;
	#Redmi 12C
	earth) size=7514095616;;
	#Redmi Note 14 4G
	tanzanite) size=8042577920;;
	#Redmi Note 14 Pro 4G
	obsidian) size=8053063680;;
	#Redmi Note 13 Pro 4G
	emerald) size=7505707008;;
	#Others
	*) size=9126805504;;
esac
echo $size

#pipa 9126805504 |Pad6
#liuqin 9126805504 |Pad6Pro
#sunstone 9126805504 or 9122611200 |Note 12 5G
#rembrandt 9126805504 |K60E
#redwood 9126805504 |Note12ProSpeed
#mondrian 9126805504 |K60
#yunluo 9126805504 |RedmiPad
#ruby 9126805504 |Note 12 Pro
