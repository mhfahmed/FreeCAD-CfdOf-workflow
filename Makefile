
# Makefiles are containing multiple "targets" (e.g. all, openfreecad, restore, ...)
# every target will execute normal bash commands
# a target is executed from bash with:
# 		make TARGETNAME
# a target can have prerequirements, so target "all" will first execute target "clean", "mesh" and "run"
# https://en.wikipedia.org/wiki/Make_(software) 



# std workflow targets
# ======================================================

# run "make all" if you want to create everything new
all: clean mesh run


# freecad
# -----------------------------------------------

# this target opens the freecad GUI
# you can also execute the command "freecad freecad-cfd.FCStd" directly in the terminal
openfreecad:
	freecad freecad-cfd.FCStd
	make store0as0org


# after exporting files from freecad everything inside case and meshCase will be overwriten
# this target moves the folder 0 inside case to 0.org, because otherwise 0 will be overwritten from the openfoam-solver
store0as0org:
	if [ ! -d case/0.org ] ;  then      \
		echo "*** copy 0 to 0.org"  ; \
		cp -rf case/0    case/0.org   ; \
	fi ; 


# meshing
# -----------------------------------------------

# starts Allmesh script within meshCase to create the mesh
mesh: 
	cd meshCase ;  ./Allmesh


# OpenFOAM calculation
# -----------------------------------------------
copy0orgto0:
	mkdir -p case/0
	cp -rf  case/0.org/*  case/0

# run copies the initial state from 0.org to 0 and starts the Allrun script
run: store0as0org copy0orgto0
	cd case ;  ./Allrun


# reviewing created mesh and results
# -----------------------------------------------

# opens paraview for reviewing the mesh
viewMesh:
	cd meshCase  ;  paraFoam


# opens paraview for reviewing the results
viewResults:
	cd case  ;  paraFoam -builtin


zip:
	tar -vcjf archive-$(shell date +"%Y%m%d-%I%M%p").tar.bz2   --exclude='ARCHIVE' --exclude='archive' --exclude='meshCase/constant' --exclude='case/0' --exclude='case/constant/polyMesh' --exclude='case/processor*' --exclude='*.tar.gz' --exclude='*.tar.bz2'  `ls -A -1`

# split archives to 10mb parts for a better uploading
# splitArchive:
	# split -b 10M  ARCHIVE.tar.gz  ARCHIVE.tar.gz.part
# rebuildArchive:
	# cat  ARCHIVE.tar.gz.part*  >  ARCHIVE.tar.gz



# cleaning the repository
# ======================================================

# the clean target executes the clean targets cleanMesh and cleanCase to remove calculated files
clean: cleanMesh cleanCase

# deletes the mesh and the related log files
cleanMesh: cleanPreliminaryMeshes
	rm -f  meshCase/log*
	rm -f  meshCase/mesh_outside.stl
	rm -rf meshCase/constant/extendedFeatureEdgeMesh
	rm -rf meshCase/constant/polyMesh
	rm -rf meshCase/constant/triSurface/*.eMesh
	rm -rf meshCase/gmsh

cleanPreliminaryMeshes:
	rm -rf [1-9]

# deletes all files and folders created by the openFOAM-solver
cleanCase: 
	rm -rf case/log.*
	rm -rf case/0
	rm -rf case/constant/polyMesh
	rm -rf case/postProcessing
	rm -rf case/processor[0-9]


# deletes the complete FreeCAD export folders inklusive the necessary source files, which are also stored in git
deleteFreecadExports:
	rm -rf meshCase
	rm -rf case


# removes all changes in this repository and switches to the last git commit
reset: deleteFreecadExports
	git reset --hard
