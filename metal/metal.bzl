def enable_metal(repository_ctx):
    print(repository_ctx)
    return int(repository_ctx.os.environ.get("TF_NEED_METAL", False))


def _build_metallib(ctx):
    #if not enable_metal(ctx):
    #    return
    in_file = ctx.file.input
    out_file = ctx.outputs.output

    in_file_path_no_extension = in_file.path.split(".")[1]
    inermidiate_representations_file = ctx.actions.declare_file(in_file_path_no_extension + ".air")

    ctx.actions.run_shell(
        outputs = [inermidiate_representations_file],
        inputs = [in_file],
        arguments = [in_file.path, inermidiate_representations_file.path],
        command = "xcrun -sdk macosx metal -c \"$1\" -o \"$2\" -ffast-math",
    )

    ctx.actions.run_shell(
        outputs = [out_file],
        inputs = [inermidiate_representations_file],
        arguments = [inermidiate_representations_file.path, out_file.path],
        command = "xcrun -sdk macosx metallib \"$1\" -o \"$2\"",
    )



metallib = rule(
    implementation = _build_metallib,
    attrs = {
        "input": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The file containing metal kernel.",
        ),
        "output": attr.output(doc = "The name of output file."),
    },
    doc = "Compiles .metal file to .metallib."
)