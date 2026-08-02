#!/usr/bin/env python3

import csv
import sys
import xml.etree.ElementTree as ET
import zipfile

MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


def qname(namespace: str, name: str) -> str:
    return "{" + namespace + "}" + name


def column_index(cell_ref: str) -> int:
    value = 0
    for char in cell_ref:
        if not char.isalpha():
            break
        value = value * 26 + (ord(char.upper()) - ord("A") + 1)
    return value - 1


def read_shared_strings(workbook: zipfile.ZipFile) -> list[str]:
    try:
        data = workbook.read("xl/sharedStrings.xml")
    except KeyError:
        return []

    root = ET.fromstring(data)
    values: list[str] = []
    for item in root.findall(qname(MAIN_NS, "si")):
        pieces = [node.text or "" for node in item.iterfind(".//" + qname(MAIN_NS, "t"))]
        values.append("".join(pieces))
    return values


def first_sheet_path(workbook: zipfile.ZipFile) -> str:
    workbook_root = ET.fromstring(workbook.read("xl/workbook.xml"))
    sheets = workbook_root.find(qname(MAIN_NS, "sheets"))
    if sheets is None:
        raise ValueError("missing workbook sheets")
    sheet = sheets.find(qname(MAIN_NS, "sheet"))
    if sheet is None:
        raise ValueError("missing first worksheet")

    rel_id = sheet.attrib[qname(REL_NS, "id")]
    rels_root = ET.fromstring(workbook.read("xl/_rels/workbook.xml.rels"))
    for relationship in rels_root.findall(qname(PKG_REL_NS, "Relationship")):
        if relationship.attrib.get("Id") == rel_id:
            target = relationship.attrib["Target"]
            if target.startswith("/"):
                return target.lstrip("/")
            return "xl/" + target

    raise ValueError("worksheet relationship not found")


def cell_text(cell: ET.Element, shared_strings: list[str]) -> str:
    cell_type = cell.attrib.get("t")
    if cell_type == "inlineStr":
        pieces = [node.text or "" for node in cell.iterfind(".//" + qname(MAIN_NS, "t"))]
        return "".join(pieces)

    value = cell.find(qname(MAIN_NS, "v"))
    if value is None or value.text is None:
        return ""
    if cell_type == "s":
        return shared_strings[int(value.text)]
    return value.text


def iter_rows(sheet_root: ET.Element, shared_strings: list[str]):
    sheet_data = sheet_root.find(qname(MAIN_NS, "sheetData"))
    if sheet_data is None:
        raise ValueError("worksheet has no sheetData")

    for row in sheet_data.findall(qname(MAIN_NS, "row")):
        values: dict[int, str] = {}
        max_index = -1
        for cell in row.findall(qname(MAIN_NS, "c")):
            cell_ref = cell.attrib.get("r", "")
            index = column_index(cell_ref)
            values[index] = cell_text(cell, shared_strings)
            max_index = max(max_index, index)

        if max_index >= 0:
            row_values = [values.get(index, "") for index in range(max_index + 1)]
            if any(value != "" for value in row_values):
                yield row_values


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: xlsx_to_sorting_csv.py <input.xlsx> <output.csv>", file=sys.stderr)
        return 1

    input_path, output_path = sys.argv[1:3]

    with zipfile.ZipFile(input_path) as workbook:
        shared_strings = read_shared_strings(workbook)
        sheet_path = first_sheet_path(workbook)
        sheet_root = ET.fromstring(workbook.read(sheet_path))
        rows = list(iter_rows(sheet_root, shared_strings))

    with open(output_path, "w", encoding="utf-8", newline="") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerows(rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
