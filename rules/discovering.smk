rule bowtie_build_index:
    input:
        resolve_single_filepath(*references_abs_path(ref='genome_reference'),
                                config.get("genome_fasta"))
    output:
        touch("bowtie_index_ready"),
        genome="{label}.fa".format(label=get_references_label(ref='genome_reference'))
    conda:
        "envs/bowtie.yaml"
    params:
        label=get_references_label(ref='genome_reference')
    threads: pipeline_cpu_count()
    log: "logs/bowtie/build_index.log"
    shell:
        "rsync -av {input} {output.genome} "
        "&& bowtie-build "
        "--threads {threads} "
        "{output.genome} {params.label} "
        "&>{log} "


rule mirdeep2_alignment:
    input:
        "trimmed/{sample}-trimmed.fq",
        index_ready="bowtie_index_ready",
    output:
        fa=temp("discovering/{sample}_deepseq.fa"),
        arf="discovering/{sample}_reads_vs_genome.arf"
    shadow: "shallow"
    conda:
        "envs/mirdeep2.yaml"
    params:
        params=config.get("rules").get("mirdeep2_alignment").get("params"),
        label=get_references_label(ref='genome_reference')
    log:
        "logs/mirdeep2/{sample}_alignment.log"
    threads: pipeline_cpu_count()
    shell:
        "mapper.pl "
        "{input[0]} "
        "{params.params} "
        "-p {params.label} "
        "-s {output.fa} "
        "-t {output.arf} "
        "-o {threads} "
        "&> {log} "


rule mirdeep2_identification:
    input:
        fa="discovering/{sample}_deepseq.fa",
        arf="discovering/{sample}_reads_vs_genome.arf",
        genome=resolve_single_filepath(*references_abs_path(ref='genome_reference'),
                                config.get("genome_fasta")),
        miRNAs_ref=resolve_single_filepath(*references_abs_path(ref='mirna_reference'),
                                config.get("mirna_ref")),
        miRNAs_other=resolve_single_filepath(*references_abs_path(ref='mirna_reference'),
                                config.get("mirna_other")),
        miRNAs_ref_precursors=resolve_single_filepath(*references_abs_path(ref='mirna_reference'),
                                config.get("mirna_ref_precursors"))
    output:
        touch("discovering/mirdeep2.{sample}.end")
    shadow: "shallow"
    conda:
        "envs/mirdeep2.yaml"
    params:
        params=config.get("rules").get("mirdeep2_identification").get("params"),
        prefix=lambda wildcards: wildcards.sample
    log:
        "logs/mirdeep2/{sample}_identification.log"
    shell:
        "miRDeep2.pl "
        "{input.fa} "
        "{input.genome} "
        "{input.arf} "
        "{input.miRNAs_ref} "
        "{input.miRNAs_other} "
        "{input.miRNAs_ref_precursors} "
        "-r {params.prefix} "
        "{params.params} "
        "&> {log} "




