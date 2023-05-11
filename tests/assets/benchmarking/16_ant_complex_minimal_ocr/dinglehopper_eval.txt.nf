nextflow.enable.dsl = 2

params.workspace_path = "/home/michelleweidling/git/forks/quiver-back-end/workflows/workspaces/CURRENT/"
params.mets_path = "/home/michelleweidling/git/forks/quiver-back-end/workflows/workspaces/CURRENT/mets.xml"
params.docker_pwd = "/ocrd-workspace"
params.docker_volume = "$params.workspace_path:$params.docker_pwd"
params.docker_models_dir = "/usr/local/share/ocrd-resources"
params.models_path = "\$HOME/ocrd_models"
params.docker_models = "$params.models_path:$params.docker_models_dir"
params.docker_image = "ocrd/all:maximum"
params.docker_command = "docker run --rm -u \$(id -u) -v $params.docker_volume -v $params.docker_models -w $params.docker_pwd -- $params.docker_image"

process ocrd_dinglehopper_0 {
  maxForks 1

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
    """
    ${params.docker_command} ocrd-dinglehopper -I ${input_dir} -O ${output_dir}
    """
}

workflow {
  main:
    ocrd_dinglehopper_0(params.mets_path, "OCR-D-GT-SEG-LINE,OCR-D-OCR", "OCR-D-EVAL-SEG-LINE")
}


