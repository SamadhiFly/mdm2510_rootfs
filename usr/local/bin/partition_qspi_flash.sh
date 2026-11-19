if [ -f /etc/qspi_partitions.txt ]; then
    echo "Creating static qspi partitions"
    cat /etc/qspi_partitions.txt | while read masterdev name start size; do
        test -n "$masterdev" && mtdpart add $masterdev $name $start $size
    done
fi

test -f /usr/local/bin/create_dynamic_qspi_partitions.sh && /usr/local/bin/create_dynamic_qspi_partitions.sh
