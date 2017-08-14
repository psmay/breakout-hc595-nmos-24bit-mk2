
PROJECT=breakout-hc595-nmos-24bit-mk2
SCHEMATIC_X=schematic
LAYOUT_X=layout
LAYOUT_TOP_X=$(LAYOUT_X)-top
LAYOUT_BOTTOM_X=$(LAYOUT_X)-bottom
LAYER_TOP=1
LAYER_BOTTOM=2
LAYER_OUTLINE=7
BUILD=build
PDF_PRODUCTS = $(SCHEMATIC_X).pdf $(LAYOUT_X).pdf
PNG_PRODUCTS = $(SCHEMATIC_X).png $(LAYOUT_TOP_X).png $(LAYOUT_BOTTOM_X).png
DISPLAY_PRODUCTS = $(PNG_PRODUCTS)

default: $(DISPLAY_PRODUCTS)

$(BUILD):
	mkdir -p $@

distclean: clean
	rm -vf $(DISPLAY_PRODUCTS)
	rm -vf *.pcb- *.sch~ *.bak *.bak[0-9] *.bak[0-9][0-9] *.backup *.net *.save

clean:
	rm -rvf $(BUILD)
	rm -rvf $(PROJECT).*.gbr $(PROJECT).*.cnc

$(SCHEMATIC_X).pdf: $(BUILD)/schematic.pdf
	cp $^ $@

$(LAYOUT_X).pdf: $(BUILD)/layout.pdf
	cp $^ $@

$(SCHEMATIC_X).png: $(BUILD)/schematic.png
	cp $^ $@

$(LAYOUT_TOP_X).png: $(BUILD)/layout-top.png
	cp $^ $@

$(LAYOUT_BOTTOM_X).png: $(BUILD)/layout-bottom.png
	cp $^ $@




$(BUILD)/schematic.pdf: $(PROJECT).sch | $(BUILD)
	gaf export -o $@ $^

$(BUILD)/schematic.png: $(BUILD)/schematic.pdf | $(BUILD)
	convert -density 200x200 $^ -scale 40% $@

$(BUILD)/layout.ps: $(PROJECT).pcb | $(BUILD)
	pcb -x ps --psfile $@ $^

$(BUILD)/layout.pdf: $(BUILD)/layout.ps | $(BUILD)
	ps2pdf $^ $@

$(BUILD)/layout-top-nooutline.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "top,silk" --layer-color-$(LAYER_TOP) '#000088' --element-color '#FFFFFF' --as-shown --eps-file $@ $^

$(BUILD)/layout-top-outlineonly.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "outline" --layer-color-$(LAYER_OUTLINE) '#FF8800' --as-shown --eps-file $@ $^

$(BUILD)/layout-top.png: $(BUILD)/layout-top-nooutline.eps $(BUILD)/layout-top-outlineonly.eps | $(BUILD)
	./autosize-and-compose-layout.sh $^ $@

$(BUILD)/layout-bottom-nooutline.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "bottom,silk,solderside" --layer-color-$(LAYER_BOTTOM) '#000088' --element-color '#FFFFFF' --as-shown --eps-file $@ $^

$(BUILD)/layout-bottom-outlineonly.eps: $(PROJECT).pcb | $(BUILD)
	pcb -x eps --layer-stack "outline,solderside" --layer-color-$(LAYER_OUTLINE) '#FF8800' --as-shown --eps-file $@ $^

$(BUILD)/layout-bottom.png: $(BUILD)/layout-bottom-nooutline.eps $(BUILD)/layout-bottom-outlineonly.eps | $(BUILD)
	./autosize-and-compose-layout.sh $^ $@

$(BUILD)/gerber-files: $(PROJECT).pcb | $(BUILD)
	rm -rf $@
	mkdir -p $@
	pcb -x gerber --gerberfile $@/$(PROJECT) $<
	# By default the plated drill file is used as the only drills.
	# If there are other drill files, do make gerbv-drills before
	# make gerbers[-mfr] to run gerbv and merge the drill files.
	cp -f $@/$(PROJECT).plated-drill.cnc $@/$(PROJECT).drill.cnc.tmp
	for i in $@/*.cnc; do mv -v $$i $$i.UNMERGED; done
	mv $@/$(PROJECT).drill.cnc.tmp $@/$(PROJECT).drill.cnc

export-gerbers: $(BUILD)/gerber-files

gerbv-drills: export-gerbers
	gerbv $(BUILD)/gerber-files/*.cnc.UNMERGED

plated-drills-only: export-gerbers
	cp -f $(BUILD)/gerber-files/$(PROJECT).plated-drill.cnc.UNMERGED $(BUILD)/gerber-files/$(PROJECT).drill.cnc

$(BUILD)/$(PROJECT)-gerbers.zip: $(BUILD)/gerber-files | $(BUILD)
	rm -rf $@
	zip -j $@ $</*.gbr $</*.cnc 

$(BUILD)/gerber-files-dirtypcbs: $(BUILD)/gerber-files | $(BUILD)
	rm -rf $@
	mkdir -p $@
	cp $</$(PROJECT).top.gbr $@/$(PROJECT).gtl
	cp $</$(PROJECT).topmask.gbr $@/$(PROJECT).gts
	cp $</$(PROJECT).topsilk.gbr $@/$(PROJECT).gto
	cp $</$(PROJECT).bottom.gbr $@/$(PROJECT).gbl
	cp $</$(PROJECT).bottommask.gbr $@/$(PROJECT).gbs
	cp $</$(PROJECT).bottomsilk.gbr $@/$(PROJECT).gbo
	cp $</$(PROJECT).outline.gbr $@/$(PROJECT).gbr
	cp $</$(PROJECT).*.cnc $@/$(PROJECT)-drill.txt

$(BUILD)/$(PROJECT)-gerbers-dirtypcbs.zip: $(BUILD)/gerber-files-dirtypcbs | $(BUILD)
	rm -rf $@
	zip -j $@ $</*.g[tb][lso] $</*.gbr $</*.txt 

gerbers: $(BUILD)/$(PROJECT)-gerbers.zip

gerbers-dirtypcbs: $(BUILD)/$(PROJECT)-gerbers-dirtypcbs.zip

