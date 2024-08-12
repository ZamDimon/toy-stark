for i in *.sage; do
    [ -f "$i" ] || break
    sage --preparse $i
    mv -v $i.py ${i%.*}.py
done

sage main.sage
