for i in $(find . -type f -name "*.sage"); do
    [ -f "$i" ] || break
    sage --preparse $i
    mv -v $i.py ${i%.*}.py
done

sage main.sage
