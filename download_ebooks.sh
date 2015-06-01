#!/bin/bash

# Batch download ebooks from the website it-ebooks.info
# Classify according to the publisher

URL="http://it-ebooks.info/book/"
TMPFILE=download_books_temp
book_num=1
book_count=0

download_book()
{
    if [ -f "$1" ]
    then
        echo "Book \"$1\" already exists."
        return
    fi

    btime=`date +"%m-%d-%Y %H:%M:%S"`
    echo ${btime}" Begin to download book \"$1\", please wait..."

    wget -q -O "$1" --referer=${URL}${book_num} $2

    # Check whether the file is complete
    if [ "$?" != 0 ]
    then
        echo "Download book \"$1\" error."

        if [ ! -f "$1" ]
        then
            rm "$1"
            return
        fi
    fi
    
    book_count=`expr ${book_count} + 1`
    etime=`date +"%m-%d-%Y %H:%M:%S"`
    echo ${etime}" Download finished"
}

download_all()
{
    # Request book information and store to the temp file
    result=$(curl -w %{http_code} -s --output ${TMPFILE} ${URL}${book_num}'/')

    while [ ${result}="200" ]
    do
        # Get information from temp file
        book_name=`grep  "<h1 itemprop=\"name\">" ${TMPFILE} | sed 's/<[^>]*>//g' | tr -d '\r'`
        publisher=`grep  "publisher" ${TMPFILE} | sed 's/<[^>]*>//g' | awk -F: '{print $2}' | tr -d '\r'`
        REALURL=`grep  -P -o "http://filepi.com/i/[a-zA-Z0-9]*" ${TMPFILE}`

        if [ X"${book_name}" = "X" ] || [ X"${publisher}" = "X" ] || [ X"${REALURL}" = "X" ]
        then
            echo "Error: no information"
            continue
        fi

        # Create dir according to the publisher
        if [ ! -d "${publisher}" ]
        then
            mkdir "${publisher}"
        fi

        # Download book
        cd "${publisher}"
        download_book "${book_name}" "${REALURL}"
        cd ../

        book_num=`expr ${book_num} + 1`
        result=$(curl -w %{http_code} -s --output ${TMPFILE} ${URL}${book_num}'/')
    done

    echo "Download finished with http code "${result}
    echo "Totally" ${book_count} "books have been downloaded"
}

download_all
rm ${TMPFILE}
exit 0
