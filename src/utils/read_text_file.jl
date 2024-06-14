# read text file

# exports
export read_text

# code
"""
function read_text(fname::String, dirname::String=".", nlines=10)

Print first few lines from text file.

fname:          File name
dirname:        Directory name
nlines:         Number of lines to read and print
"""

function read_text(fname::String, dirname::String=".", nlines=10)

    open(joinpath(dirname, fname)) do f
        
        while nlines > 0

            l = readline(f)
            println(l)
            nlines -= 1

        end
    end

    return nothing
end