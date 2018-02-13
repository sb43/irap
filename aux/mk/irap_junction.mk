#; -*- mode: Makefile;-*-
# =========================================================
# Copyright 2012-2018,  Nuno A. Fonseca (nuno dot fonseca at gmail dot com)
#
# This file is part of iRAP.
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with iRAP.  If not, see <http://www.gnu.org/licenses/>.
#
#
# =========================================================

# Collect and process junctions files generated by the different mappers
junction_quant?=n

ifeq ($(junction_quant),y)

JUNCTION_QUANT_SUPPORTED_MAPPERS=star tophat2

ifeq (,$(filter $(mapper),$(JUNCTION_QUANT_SUPPORTED_MAPPERS)))
$(call p_info,[ERROR] junction quantification (junction_quant=y) can only be enabled with the following mappers: $(JUNCTION_QUANT_SUPPORTED_MAPPERS))
$(error junction_quant should be set to n)
endif
# Collect, enable and/or perform junction/splicing quantification

JUNCTION_TARGETS=$(foreach p,$(pe),$(call lib2bam_folder,$(p))$(p).juncs.tsv) $(foreach p,$(se),$(call lib2bam_folder,$(p))$(p).juncs.tsv)

STAGE3_OUT_FILES+=$(JUNCTION_TARGETS) $(mapper_toplevel_folder)/junctions.tsv
STAGE3_S_TARGETS+=$(JUNCTION_TARGETS)
STAGE3_TARGETS+=$(mapper_toplevel_folder)/junctions.tsv
# WAVE
WAVE3_TARGETS+=$(JUNCTION_TARGETS)
WAVE4_TARGETS+=$(mapper_toplevel_folder)/junctions.tsv

## juncs file
## chr:coord1:coord2:strand:intron_motif reads
ifeq (tophat2,$(mapper))

define make-pe-junction-rule=
$(call lib2bam_folder,$(1))$(1).juncs.tsv: $(call lib2bam_folder,$(1))$(1)/junctions.bed $(call lib2bam_folder,$(1))$(1).pe.hits.bam 
	tail -n +2  $$< | awk 'BEGIN {OFS="\t";} {print  $$$$1":"$$$$2":"$$$$3":"$$$$6":"0,$$$$5;}' > $$@.tmp && mv $$@.tmp $$@
endef 

define make-se-junction-rule=
$(call lib2bam_folder,$(1))$(1).juncs.tsv: $(call lib2bam_folder,$(1))$(1)/junctions.bed $(call lib2bam_folder,$(1))$(1).se.hits.bam
	tail -n +2  $$< | awk 'BEGIN {OFS="\t";} {print  $$$$1":"$$$$2":"$$$$3":"$$$$6":"0,$$$$5;}' > $$@.tmp && mv $$@.tmp $$@
endef

endif

# 
#ifeq (hisat2,$(mapper))
#define make-pe-junction-rule=
## define a function in the irap_map.mk to get the junction file for a library
#$(call lib2bam_folder,$(1))$(1).juncs.tsv: $(call lib2bam_folder,$(1))$(1).pe.hits.bam.splicing.tsv  $(call lib2bam_folder,$(1))$(1).pe.hits.bam 
#	cp $$< $$@
#endef

#define make-se-junction-rule=
#$(call lib2bam_folder,$(1))$(1).juncs.tsv: $(call lib2bam_folder,$(1))$(1).se.hits.bam.splicing.tsv  $(call lib2bam_folder,$(1))$(1).se.hits.bam 
#	cp $$< $$@
#endef
#endif

# column 1: chromosome
# column 2: first base of the intron (1-based)
# column 3: last base of the intron (1-based)
# column 4: strand (0: undefined, 1: +, 2: -)
# column 5: intron motif: 0: non-canonical; 1: GT/AG, 2: CT/AC, 3: GC/AG, 4: CT/GC, 5:AT/AC, 6: GT/AT
# column 6: 0: unannotated, 1: annotated (only if splice junctions database is used)
# column 7: number of uniquely mapping reads crossing the junction
# column 8: number of multi-mapping reads crossing the junction
# column 9: maximum spliced alignment overhang
ifeq (star,$(mapper))
define make-pe-junction-rule=
# define a function in the irap_map.mk to get the junction file for a library
$(call lib2bam_folder,$(1))$(1).juncs.tsv: $(call lib2bam_folder,$(1))$(1)/SJ.out.tab  $(call lib2bam_folder,$(1))$(1).pe.hits.bam
	tail -n +2  $$< | awk 'BEGIN {OFS="\t";} {print  $$$$1":"$$$$2":"$$$$3":"$$$$4":"$$$$5,$$$$7;}'|sed -E "s/:1:([0-9]\s)/:+:\\1/;s/:2:([0-9]\s)/:-:\\1/" > $$@.tmp && mv $$@.tmp $$@
endef

define make-se-junction-rule=
$(call lib2bam_folder,$(1))$(1).juncs.tsv: $(call lib2bam_folder,$(1))$(1)/SJ.out.tab  $(call lib2bam_folder,$(1))$(1).se.hits.bam
	tail -n +2  $$< | awk 'BEGIN {OFS="\t";} {print  $$$$1":"$$$$2":"$$$$3":"$$$$4":"$$$$5,$$$$7;}'|sed -E "s/:1:([0-9]\s)/:+:\\1/;s/:2:([0-9]\s)/:-:\\1/" > $$@.tmp && mv $$@.tmp $$@
endef
endif

########################
# rules for SE libraries
$(foreach l,$(se),$(eval $(call make-se-junction-rule,$(l))))
# rules for PE libraries
$(foreach l,$(pe),$(eval $(call make-pe-junction-rule,$(l))))

########################
# Merge
$(mapper_toplevel_folder)/junctions.tsv: $(JUNCTION_TARGETS)
	$(call pass_args_stdin,irap_merge_mtx,$@.tmp, --is_tsv  --add_header --basename_header --in='$(subst $(space),;,$^)'  --out $@.tmp) && sed "1s/.juncs.tsv//g" $@.tmp > $@

endif



