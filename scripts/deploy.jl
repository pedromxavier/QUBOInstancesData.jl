using Tar
using UUIDs

include("_util.jl")

function main(; verbose::Bool=false)
    # copy 'LICENSE' and '.gitignore' into 'collections'
    cp(
        joinpath(ROOT_PATH, "LICENSE"),
        joinpath(DATA_PATH, "LICENSE"),
    )
    cp(
        joinpath(ROOT_PATH, ".gitignore"),
        joinpath(DATA_PATH, ".gitignore"),
    )

    # build tarball
    filepath = Tar.create(DATA_PATH) |> abspath

    # compress
    run(`gzip -9 $filepath`)
    
    # copy from temporary file and delete it
    distpath = joinpath(DIST_PATH, "dist.tar.gz")

    cp("$filepath.gz", distpath)

    rm(filepath; force = true)

    cd(ROOT_PATH) do
        # Generate name for temporary branch
        branch = string(uuid4())

        # Create 'dist' branch if not exists, reset it otherwise
        run(`git checkout -B dist`)

        # Move to temporary branch
        run(`git checkout --orphan $branch`)

        # Delete everything from git history
        run(`git rm -rf .`)

        # Assert that 'dist' folder is still there
        @assert isdir(DIST_PATH)

        # Bring '.gitignore' and 'LICENSE' back from the 'main' branch
        run(`git checkout main -- .gitignore LICENSE`)

        # Add 'dist' folder and the aforementioned files back
        run(`git add .`)

        # Commit
        run(`git commit -m "Distribute data"`)

        # Upload branch (is this necessary?)
        run(`git push --set-upstream origin $branch`)

        # Overwrite 'dist' branch with contents from temporary branch
        run(`git push origin +$branch:dist`)

        # Move to the 'main' branch
        run(`git checkout main`)

        # Delete temporary branch locally ...
        run(`git branch -d $branch`)

        # ... and remotely
        run(`git push origin --delete $branch`)
    end

    return nothing
end

if "--run" ∈ ARGS
    if "--verbose" ∈ ARGS
        main(; verbose=true)
    else
        main()
    end
end
