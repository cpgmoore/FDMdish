#!/bin/sh


#Auth CPGMoore
#Lic
#Date
#Purpose
#Ref to 
#Run this script, check the output by importing all stl files into freecad. Their locations and orientations should appear in their final assembled place
#OpenSCAD doesn't utilise multithreaded processing
#But we can cut down on execution time by having each tile rendered by OpenSCAD in a seperate subshell, multithreading by component!

THREAD_LIMIT=8 #adjust this to suit the number of available logical CPU cores

: '
#on axis, 4 tiles, total 400x400mm
F=200
PRINT_DIM=200
TILES_C_X=(-100 +100)
TILES_C_Y=(-100 +100)
'

#on axis, 16 tiles, total 800x800
F=500
PRINT_DIM=200
#The below array identifies the centered location of each of the tiles to export, adjust according to your desired layout
TILES_C_X=(-300 -100 +100 +300)
TILES_C_Y=(-300 -100 +100 +300)


: '
#on axis, 16 tiles, total 1000x1000
F=500
PRINT_DIM=200
#The below array identifies the centered location of each of the tiles to export, adjust according to your desired layout
TILES_C_X=(-500 -300 -100 +100 +300 +500)
TILES_C_Y=(-500 -300 -100 +100 +300 +500)
'

: '
#off axis, 4 tiles, total 400x400
F=250
PRINT_DIM=200
#The below array identifies the centered location of each of the tiles to export, adjust according to your desired layout
TILES_C_X=( -100 +100)
TILES_C_Y=( +100 +300)
'

: '
F=500
PRINT_DIM=200 #Print_dim must be a multiple of 20 for the holes to line up
#The below array identifies the centered location of each of the tiles to export, adjust according to your desired layout
TILES_C_X=(-400 -200 0 +200 +400)
TILES_C_Y=(-400 -200 0 +200 +400)
'

: '
F=1000
PRINT_DIM=200 #Print_dim must be a multiple of 20 for the holes to line up
#The below array identifies the centered location of each of the tiles to export, adjust according to your desired layout
TILES_C_X=(-800 -600 -400 -200 0 +200 +400 +600 +800)
TILES_C_Y=(-800 -600 -400 -200 0 +200 +400 +600 +800)
'

: '
#off axis, 4 tiles, total 600x600
F=600
PRINT_DIM=300
#The below array identifies the centered location of each of the tiles to export, adjust according to your desired layout
TILES_C_X=(-150 +150)
TILES_C_Y=(+150 +450)
'

echo "This script will generate a dish with:"
echo "	Focal distance: "${F}
echo "	Tile print volume dimension: "${PRINT_DIM}
echo "	Center locations of tiles in X dimension: "${TILES_C_X[*]}
echo "	Center locations of tiles in Y dimension: "${TILES_C_Y[*]}
echo ""

mkdir render
cd render

THREAD_COUNTER=0
for TILE_C_X in ${TILES_C_X[@]}
do
	for TILE_C_Y in ${TILES_C_Y[@]}
	do
		FILENAME_OUT=dish_F${F}_tile_${PRINT_DIM}_${TILE_C_X}_${TILE_C_Y}.stl 
		echo "Rendering " ${FILENAME_OUT} " ..."
		#Windows:
		'C:\Program Files\OpenSCAD\openscad.exe' -o ${FILENAME_OUT} ../dish.scad \
												-D paraboloid_focal_length_mm=${F}\
												-D tile_dim_mm=${PRINT_DIM}\
												-D tile_location_x=${TILE_C_X}\
												-D tile_location_y=${TILE_C_Y} &
		
		THREAD_COUNTER=$((THREAD_COUNTER+1))
		if [ "$THREAD_COUNTER" -ge "$THREAD_LIMIT" ]
		then
			echo "Waiting for subshells to complete..."
			wait
			THREAD_COUNTER=0
		fi
		
	done

	
done

wait
