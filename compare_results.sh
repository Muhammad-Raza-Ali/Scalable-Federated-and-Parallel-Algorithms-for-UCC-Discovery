#!/bin/bash

LEGACY_DIR="$HOME/enumhyp/result"
STANDARD_DIR="$HOME/enumhyp/standard"
COMPARE_DIR="$HOME/enumhyp/comparison"

mkdir -p "$COMPARE_DIR"

SUMMARY="$COMPARE_DIR/comparison.csv"

echo "graph,legacy_file,standard_file,status,legacy_lines,standard_lines" \
    > "$SUMMARY"

GRAPHS=(
    "abalone.graph"
    "amalgam1.graph"
    "call_a_bike.graph"
    "civil_service.graph"
    "echocardiogram.graph"
    "fd_reduced_15.graph"
    "fd_reduced_30.graph"
    "flight_1k.graph"
    "hepatitis.graph"
    "horse.graph"
    # "ncvoter_allc.graph"
    "uniprot.graph"
)

echo "================================================="
echo "EnumHyp RESULT COMPARISON"
echo "================================================="
echo "Legacy directory:   $LEGACY_DIR"
echo "Standard directory: $STANDARD_DIR"
echo "================================================="

TOTAL=0
MATCH=0
ORDER_ONLY=0
DIFFERENT=0
MISSING=0

for GRAPH_NAME in "${GRAPHS[@]}"; do

    TOTAL=$((TOTAL + 1))

    BASE="${GRAPH_NAME%.graph}"

    LEGACY_FILE="$LEGACY_DIR/${BASE}_MPI.out"
    STANDARD_FILE="$STANDARD_DIR/${BASE}_STANDARD.out"

    echo
    echo "-------------------------------------------------"
    echo "Comparing: $BASE"
    echo "-------------------------------------------------"

    if [[ ! -f "$LEGACY_FILE" ]]; then
        echo "MISSING legacy file:"
        echo "  $LEGACY_FILE"

        echo \
            "$GRAPH_NAME,$LEGACY_FILE,$STANDARD_FILE,MISSING_LEGACY,0,0" \
            >> "$SUMMARY"

        MISSING=$((MISSING + 1))
        continue
    fi

    if [[ ! -f "$STANDARD_FILE" ]]; then
        echo "MISSING standard file:"
        echo "  $STANDARD_FILE"

        LEGACY_LINES=$(wc -l < "$LEGACY_FILE")

        echo \
            "$GRAPH_NAME,$LEGACY_FILE,$STANDARD_FILE,MISSING_STANDARD,$LEGACY_LINES,0" \
            >> "$SUMMARY"

        MISSING=$((MISSING + 1))
        continue
    fi

    LEGACY_LINES=$(wc -l < "$LEGACY_FILE")
    STANDARD_LINES=$(wc -l < "$STANDARD_FILE")

    #
    # Test 1:
    # Exact byte-for-byte equality
    #
    if cmp -s "$LEGACY_FILE" "$STANDARD_FILE"; then

        echo "SUCCESS: EXACTLY IDENTICAL"

        STATUS="EXACT_MATCH"
        MATCH=$((MATCH + 1))

    else

        #
        # Test 2:
        # Compare graph header separately and sort the edges.
        #

        LEGACY_HEADER=$(head -n 1 "$LEGACY_FILE")
        STANDARD_HEADER=$(head -n 1 "$STANDARD_FILE")

        if [[ "$LEGACY_HEADER" != "$STANDARD_HEADER" ]]; then

            echo "FAILED: vertex-count/header differs"
            echo "Legacy header:   $LEGACY_HEADER"
            echo "Standard header: $STANDARD_HEADER"

            STATUS="DIFFERENT_HEADER"
            DIFFERENT=$((DIFFERENT + 1))

        else

            LEGACY_SORTED="$COMPARE_DIR/${BASE}_legacy.sorted"
            STANDARD_SORTED="$COMPARE_DIR/${BASE}_standard.sorted"

            tail -n +2 "$LEGACY_FILE" \
                | sed '/^[[:space:]]*$/d' \
                | sort \
                > "$LEGACY_SORTED"

            tail -n +2 "$STANDARD_FILE" \
                | sed '/^[[:space:]]*$/d' \
                | sort \
                > "$STANDARD_SORTED"

            if cmp -s "$LEGACY_SORTED" "$STANDARD_SORTED"; then

                echo "SUCCESS: SAME MINIMAL HITTING SETS"
                echo "Difference is only output ordering."

                STATUS="SAME_SETS_DIFFERENT_ORDER"
                ORDER_ONLY=$((ORDER_ONLY + 1))

            else

                echo "FAILED: RESULTS ARE DIFFERENT"

                STATUS="DIFFERENT_RESULTS"
                DIFFERENT=$((DIFFERENT + 1))

                DIFF_FILE="$COMPARE_DIR/${BASE}.diff"

                diff \
                    "$STANDARD_SORTED" \
                    "$LEGACY_SORTED" \
                    > "$DIFF_FILE" || true

                echo "Difference saved to:"
                echo "  $DIFF_FILE"

            fi

        fi

    fi

    echo "Legacy lines:   $LEGACY_LINES"
    echo "Standard lines: $STANDARD_LINES"

    echo \
        "$GRAPH_NAME,$LEGACY_FILE,$STANDARD_FILE,$STATUS,$LEGACY_LINES,$STANDARD_LINES" \
        >> "$SUMMARY"

done

echo
echo "================================================="
echo "COMPARISON COMPLETE"
echo "================================================="
echo "Total datasets:             $TOTAL"
echo "Exact matches:              $MATCH"
echo "Same sets/different order:  $ORDER_ONLY"
echo "Different results:          $DIFFERENT"
echo "Missing results:            $MISSING"
echo "================================================="

echo
echo "Detailed summary:"
column -s, -t "$SUMMARY" 2>/dev/null || cat "$SUMMARY"

echo
echo "Comparison report:"
echo "$SUMMARY"