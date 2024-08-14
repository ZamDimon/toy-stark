for i in $(find . -type f -name "*.sage"); do
    [ -f "$i" ] || break
    sage --preparse $i
    echo "Interpreting sage file $i.py to ${i%.*}.py..."
    mv $i.py ${i%.*}.py
done

sage main.sage
