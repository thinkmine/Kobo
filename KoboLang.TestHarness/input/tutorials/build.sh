#!/bin/bash
echo ""
echo "Kobo Language Sample"
echo ""
echo "====================== 0 ======================"
echo ""
kobo run --source 0.comments.kobo --markdown ./markdown/0.comments.md

echo ""
echo "====================== 1 ======================"
echo ""
kobo run --source 1.variables.kobo --markdown ./markdown/1.variables.md

echo ""
echo "====================== 2 ======================"
echo ""
kobo run --source 2.strings.kobo --markdown ./markdown/2.strings.md

echo ""
echo "====================== 3 ======================"
echo ""
kobo run --source 3.variables-advanced.kobo --markdown ./markdown/3.variables-advanced.md

echo ""
echo "====================== 4 ======================"
echo ""
kobo build --source 4.namespaces.kobo --markdown ../markdown/4.namespaces.md --output-directory ./output

echo ""
echo "====================== 5 ======================"
echo ""
kobo run --source 5.controlflow.kobo --markdown ./markdown/5.controlflow.md

echo ""
echo "====================== 6 ======================"
echo ""
kobo build --source 6.functions.kobo --markdown ../markdown/6.functions.md --output-directory ./output

echo ""
echo "====================== 7 ======================"
echo ""
kobo build --source 7.types.kobo --markdown ../markdown/7.types.md --output-directory ./output

echo ""
echo "====================== 8 ======================"
echo ""
kobo run --source 8.partners.kobo --markdown ./markdown/8.partners.md

echo ""
echo "====================== 9 ======================"
echo ""
kobo run --source 9.operatoroverloading.kobo --markdown ./markdown/9.operatoroverloading.md

echo ""
echo "====================== 10 ======================"
echo ""
kobo run --source 10.extensions.kobo --markdown ./markdown/10.extensions.md

echo ""
echo "====================== 11 ======================"
echo ""
kobo run --source 11.advanced.kobo --markdown ./markdown/11.advanced.md

echo ""
echo "====================== 12 ======================"
echo ""
kobo run --source 12.ai.kobo --markdown ./markdown/12.ai.md

echo ""
echo "====================== 13 ======================"
echo ""
kobo run --source 13.skill.kobo --markdown ./markdown/13.skill.md -- hello

echo ""
echo "====================== 14 ======================"
echo ""
kobo run --source 14.render.kobo --markdown ./markdown/14.render.md

echo ""
echo "====================== 15 ======================"
echo ""
kobo build --source 15.sections.kobo --markdown ../markdown/15.sections.md --output-directory ./output