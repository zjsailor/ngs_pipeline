############
#       GATK_RNASeq
############
############
#       GATK Best Practices
############
rule GATK_RNASeq_Trim:
        input:  bam="{base}/{TIME}/{sample}/{sample}.star.dd.bam",
                bai="{base}/{TIME}/{sample}/{sample}.star.dd.bam.bai",
                ref=config["reference"],
                phase1=config["1000G_phase1"],
                mills=config["Mills_and_1000G"]
        output:
                bam=temp("{base}/{TIME}/{sample}/{sample}.star.trim.bam"),
                index=temp("{base}/{TIME}/{sample}/{sample}.star.trim.bai"),
        version: config["GATK"]
        params:
                rulename  = "gatk_R",
                batch     = config[config['host']]["job_gatk"]
        shell: """
        #######################
        module load GATK/{version}
        java -Xmx${{MEM}}g -Djava.io.tmpdir=${{LOCAL}} -jar $GATK_JAR -T SplitNCigarReads -R {input.ref} -I {input.bam} -o {output.bam} -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS
        ######################
        """
############
#       GATK Best Practices
############
rule GATK_RNASeq_RTC:
        input:  bam="{base}/{TIME}/{sample}/{sample}.star.trim.bam",
                bai="{base}/{TIME}/{sample}/{sample}.star.trim.bai",
                ref=config["reference"],
                phase1=config["1000G_phase1"],
                mills=config["Mills_and_1000G"]
        output:
                intervals=temp("{base}/{TIME}/{sample}/{sample}.star.realignment.intervals"),
        version: config["GATK"]
        params:
                rulename  = "gatk_R",
                batch     = config[config['host']]["job_gatk"]
        shell: """
        #######################
        module load GATK/{version}
        java -Xmx${{MEM}}g -Djava.io.tmpdir=${{LOCAL}} -jar $GATK_JAR -T RealignerTargetCreator -nt 10 -R {input.ref} -known {input.phase1} -known {input.mills} -I {input.bam} -o {output.intervals}
        ######################
        """
############
#       GATK Best Practices
############
rule GATK_RNASeq_IR:
        input:  bam="{base}/{TIME}/{sample}/{sample}.star.trim.bam",
                bai="{base}/{TIME}/{sample}/{sample}.star.trim.bai",
		intervals="{base}/{TIME}/{sample}/{sample}.star.realignment.intervals",
                ref=config["reference"],
                phase1=config["1000G_phase1"],
                mills=config["Mills_and_1000G"]
        output:
                bam=temp("{base}/{TIME}/{sample}/{sample}.star.lr.bam"),
                index=temp("{base}/{TIME}/{sample}/{sample}.star.lr.bai"),
        version: config["GATK"]
        params:
                rulename  = "gatk_R",
                batch     = config[config['host']]["job_gatk"]
        shell: """
        #######################
        module load GATK/{version}
        java -Xmx${{MEM}}g -Djava.io.tmpdir=${{LOCAL}} -jar $GATK_JAR -T IndelRealigner -R {input.ref} -known {input.phase1} -known {input.mills} -I {input.bam} --targetIntervals {input.intervals} -o {output.bam}
	######################
        """
############
#       GATK Best Practices
############
rule GATK_RNASeq_BR:
        input:  bam="{base}/{TIME}/{sample}/{sample}.star.lr.bam",
                bai="{base}/{TIME}/{sample}/{sample}.star.lr.bai",
                ref=config["reference"],
                phase1=config["1000G_phase1"],
                mills=config["Mills_and_1000G"]
        output:
                mat=temp("{base}/{TIME}/{sample}/{sample}.star.recalibration.matrix.txt"),
        version: config["GATK"]
        params:
                rulename  = "gatk_R",
                batch     = config[config['host']]["job_gatk"]
        shell: """
        #######################
        module load GATK/{version}
	java -Xmx${{MEM}}g -Djava.io.tmpdir=${{LOCAL}} -jar $GATK_JAR -T BaseRecalibrator -R {input.ref} -knownSites {input.phase1} -knownSites {input.mills} -I {input.bam} -o {output.mat}
        ######################
        """
############
#       GATK Best Practices
############
rule GATK_RNASeq_PR:
        input:  bam="{base}/{TIME}/{sample}/{sample}.star.lr.bam",
                bai="{base}/{TIME}/{sample}/{sample}.star.lr.bai",
		mat="{base}/{TIME}/{sample}/{sample}.star.recalibration.matrix.txt",
                ref=config["reference"],
                phase1=config["1000G_phase1"],
                mills=config["Mills_and_1000G"]
        output:
                bam="{base}/{TIME}/{sample}/{sample}.star.final.bam",
                index="{base}/{TIME}/{sample}/{sample}.star.final.bam.bai",
        version: config["GATK"]
        params:
                rulename  = "gatk_R",
                batch     = config[config['host']]["job_gatk_RNA"]
        shell: """
        #######################
        module load GATK/{version}
        java -Xmx${{MEM}}g -Djava.io.tmpdir=${{LOCAL}} -jar $GATK_JAR -T PrintReads -R {input.ref} -I {input.bam} -o {output.bam} -BQSR {input.mat}
        mv {wildcards.base}/{TIME}/{wildcards.sample}/{wildcards.sample}.star.final.bai {output.index}
        ######################
        """
