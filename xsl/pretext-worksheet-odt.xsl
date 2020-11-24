<?xml version='1.0'?> <!-- As XML file -->

<!--
<==================================================================>
Copyright 2020 Rob Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
<==================================================================>
-->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:officeooo="http://openoffice.org/2009/office"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
>

<xsl:import href="./pretext-common.xsl" />
<xsl:import href="./pretext-assembly.xsl"/>

<!-- Intend output is xml for an Open Document Text package (.odt file) -->
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

<!-- Math content needs to be exported to a math file before running this style sheet -->
<xsl:param name="math.mml.file" select="''"/>
<xsl:param name="math.svg.file" select="''"/>
<xsl:param name="math.speech.file" select="''"/>

<xsl:variable name="math-mml-repr" select="document($math.mml.file)/pi:math-representations"/>
<xsl:variable name="math-svg-repr" select="document($math.svg.file)/pi:math-representations"/>
<xsl:variable name="math-speech-repr" select="document($math.speech.file)/pi:math-representations"/>



<!-- ################ -->
<!-- Design variables -->
<!-- ################ -->

<!-- We must do arithmetic on dimensions, so we keep the unit separate -->
<xsl:variable name="design-unit" select="'in'" />
<!-- Page size -->
<xsl:variable name="design-page-width" select="8.5"/>
<xsl:variable name="design-page-height" select="11"/>
<!-- Margin and text size -->
<xsl:variable name="design-margin-top" select="0.7874"/>
<xsl:variable name="design-margin-bottom" select="0.7874"/>
<xsl:variable name="design-margin-left" select="0.7874"/>
<xsl:variable name="design-margin-right" select="0.7874"/>
<xsl:variable name="design-text-width" select="$design-page-width - $design-margin-left - $design-margin-right"/>
<xsl:variable name="design-text-height" select="$design-page-height - $design-margin-top - $design-margin-bottom"/>
<!-- This length is used repeatedly for indentations   -->
<!-- 0.34745in is 5ex in 12pt Latin Modern Roman       -->
<xsl:variable name="design-indent" select="0.34745" />



<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the pretext element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="pretext" mode="generic-warnings" />
    <xsl:apply-templates select="pretext" mode="deprecation-warnings" />
    <xsl:apply-templates select="pretext" />
</xsl:template>

<!-- We will totally ignore docinfo       -->
<!-- For now, just making book//worksheet -->
<xsl:template match="/pretext">
    <xsl:apply-templates select="book"/>
</xsl:template>

<!-- A book -->
<!-- For now, just drilling down to a worksheet -->
<xsl:template match="book">
    <xsl:apply-templates select="chapter"/>
</xsl:template>

<xsl:template match="chapter|section|subsection|subsubsection">
    <xsl:apply-templates select="worksheet|section|subsection|subsubsection"/>
</xsl:template>

<xsl:template match="worksheet">
    <!-- A folder to hold the subfiles, to be zipped and renamed .odt externally -->
    <!-- Note that $folder will ends with a slash                                -->
    <xsl:variable name="folder">
        <xsl:apply-templates select="." mode="folder" />
    </xsl:variable>
    <!-- Now build the six files needed for a schema-compliant .odt file -->
    <!-- Style template in particular is very long,                      -->
    <!-- so find these templates pushed to the end of this stylesheet    -->
    <xsl:apply-templates select="." mode="mimetype">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="styles">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="meta">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="settings">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="manifest">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="content">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
</xsl:template>

<!-- Kill these in an ODT worksheet -->
<xsl:template match="idx" />
<xsl:template match="notation" />

<!-- ##################################################################### -->
<!-- "p" paragraphs styled according to where they reside in the worksheet -->
<!-- ##################################################################### -->
<xsl:template match="worksheet//p">
    <text:p>
        <xsl:attribute name="text:style-name">
            <xsl:choose>
                <xsl:when test="following-sibling::*|parent::li/following-sibling::li|ancestor::ol/following-sibling::*|ancestor::ol/parent::p/following-sibling::*|ancestor::ul/following-sibling::*|ancestor::ul/parent::p/following-sibling::*|ancestor::dl/following-sibling::*|ancestor::dl/parent::p/following-sibling::*">
                    <xsl:text>P</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>P-last</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <!-- If there is a title to a block and it belongs within this p, place it here -->
        <!-- The count construct checks that the only preceding siblings are metadata   -->
        <xsl:if test="(parent::*/title or parent::statement/parent::*/title) and (count(preceding-sibling::&METADATA;) = count(preceding-sibling::*))">
            <text:span text:style-name="Runin-title">
                <xsl:choose>
                    <xsl:when test="parent::statement">
                        <xsl:apply-templates select="parent::statement/parent::*" mode="title-full"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="parent::*" mode="title-full"/>
                    </xsl:otherwise>
                </xsl:choose>
            </text:span>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates />
    </text:p>
</xsl:template>
<!-- Paragraphs, with displays within                    -->
<!-- Later, so a higher priority match                   -->
<!-- Lists and display math are ODT blocks               -->
<!-- and so should not be within an ODT paragraph.       -->
<!-- We bust them out.                                   -->
<xsl:template match="p[ol|ul|dl|me|md]">
    <!-- will later loop over lists within paragraph -->
    <xsl:variable name="displays" select="ol|ul|dl|me|md" />
    <!-- content prior to first display is exceptional, but if empty,   -->
    <!-- as indicated by $initial, we do not produce an empty paragraph -->
    <!-- all interesting nodes of paragraph, before first display       -->
    <xsl:variable name="initial" select="$displays[1]/preceding-sibling::*|$displays[1]/preceding-sibling::text()" />
    <xsl:variable name="initial-content">
        <xsl:apply-templates select="$initial"/>
    </xsl:variable>
    <xsl:variable name="needs-title" select="parent::*/title and (count(preceding-sibling::&METADATA;) = count(preceding-sibling::*))"/>
    <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
    <!-- This comparison might improve with a normalize-space()      -->
    <xsl:if test="not($initial-content='') or $needs-title">
        <text:p text:style-name="P-fragment">
            <xsl:if test="$needs-title">
                <text:span text:style-name="Runin-title">
                    <xsl:apply-templates select="parent::*" mode="title-full"/>
                </text:span>
            </xsl:if>
            <xsl:if test="not($initial-content='') and $needs-title">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="not($initial-content='')">
                <xsl:copy-of select="$initial-content" />
            </xsl:if>
        </text:p>
    </xsl:if>
    <!-- for each display, output the display, plus trailing content -->
    <xsl:for-each select="$displays">
        <!-- do the display proper -->
        <xsl:apply-templates select="." />
        <!-- look through remainder, all element and text nodes, and the next display -->
        <xsl:variable name="rightward" select="following-sibling::*|following-sibling::text()" />
        <xsl:variable name="next-display" select="following-sibling::*[self::ol or self::ul or self::dl][1]" />
        <xsl:choose>
            <xsl:when test="$next-display">
                <xsl:variable name="leftward" select="$next-display/preceding-sibling::*|$next-display/preceding-sibling::text()" />
                <!-- device below forms set intersection -->
                <xsl:variable name="common" select="$rightward[count(. | $leftward) = count($leftward)]" />
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$common" />
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <text:p text:style-name="P-fragment">
                        <xsl:copy-of select="$common-content" />
                    </text:p>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- finish the trailing content, if nonempty -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$rightward" />
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <text:p>
                        <xsl:attribute name="text:style-name">
                            <xsl:choose>
                                <xsl:when test="parent::*/following-sibling::*">
                                    <xsl:text>P</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>P-last</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:copy-of select="$common-content" />
                    </text:p>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>
<!-- Paragraphs within a table cell -->
<xsl:template match="tabular/row/cell/p">
    <xsl:variable name="col">
        <xsl:apply-templates select="parent::cell/parent::row" mode="get-column-count">
            <xsl:with-param name="up-to-cell" select="count(parent::cell/preceding-sibling::cell) + 1"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="alignment">
        <xsl:choose>
            <!-- cell attribute first -->
            <xsl:when test="ancestor::cell/@halign">
                <xsl:value-of select="ancestor::cell/@halign" />
            </xsl:when>
            <!-- parent row attribute next -->
            <xsl:when test="ancestor::row/@halign">
                <xsl:value-of select="ancestor::row/@halign" />
            </xsl:when>
            <!-- col attribute next -->
            <xsl:when test="ancestor::tabular/col[$col]/@halign">
                <xsl:value-of select="ancestor::tabular/col[$col]/@halign" />
            </xsl:when>
            <!-- table attribute last -->
            <xsl:when test="ancestor::tabular/@halign">
                <xsl:value-of select="ancestor::tabular/@halign" />
            </xsl:when>
            <!-- HTML default is left, we write it for consistency -->
            <xsl:otherwise>
                <xsl:text>left</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <text:p>
        <xsl:attribute name="text:style-name">
            <xsl:value-of select="concat('P-',$alignment)"/>
        </xsl:attribute>
        <xsl:apply-templates/>
    </text:p>
</xsl:template>

<!-- ##################################### -->
<!-- The workhseet introduction is special -->
<!-- ##################################### -->
<xsl:template match="worksheet//introduction">
    <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
    <xsl:if test="title and *[not(&METADATA-FILTER;)][position() = 1][not(self::p)]">
        <text:p text:style-name="P">
            <text:span text:style-name="Runin-title">
                <xsl:apply-templates select="." mode="title-full"/>
            </text:span>
        </text:p>
    </xsl:if>
    <xsl:apply-templates select="*[not(&METADATA;)]"/>
</xsl:template>

<!-- ####################### -->
<!-- The workhseet exercises -->
<!-- ####################### -->
<!-- TODO: extend so that an exercise need not have a statement -->
<xsl:template match="worksheet//exercise">
    <text:list-item>
        <xsl:apply-templates/>
    </text:list-item>
</xsl:template>

<xsl:template match="worksheet//statement">
    <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
    <xsl:if test="parent::*/title and *[not(&METADATA-FILTER;)][position() = 1][not(self::p)]">
        <text:p text:style-name="P">
            <text:span text:style-name="Runin-title">
                <xsl:apply-templates select="." mode="title-full"/>
            </text:span>
        </text:p>
    </xsl:if>
    <xsl:apply-templates/>
</xsl:template>

<!-- ######### -->
<!-- Groupings -->
<!-- ######### -->
<xsl:template match="abbr">
    <text:span text:style-name="Abbr">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="acro">
    <text:span text:style-name="Acro">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="init">
    <text:span text:style-name="Init">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="em">
    <text:span text:style-name="Emphasis">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="term">
    <text:span text:style-name="Term">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="alert">
    <text:span text:style-name="Alert">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="pubtitle">
    <text:span text:style-name="Pubtitle">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="articletitle">
    <text:span text:style-name="Articletitle">
        <xsl:call-template name="lq-character"/>
        <xsl:apply-templates/>
        <xsl:call-template name="rq-character"/>
    </text:span>
</xsl:template>
<xsl:template match="foreign">
    <text:span text:style-name="Foreign">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="delete">
    <text:span text:style-name="Delete">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="insert">
    <text:span text:style-name="Insert">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="stale">
    <text:span text:style-name="Stale">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="taxon[not(genus) and not(species)]">
    <text:span text:style-name="Taxon">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="taxon[genus or species]">
    <text:span text:style-name="Taxon">
        <xsl:if test="genus">
            <text:span text:style-name="Genus">
                <xsl:apply-templates select="genus"/>
            </text:span>
        </xsl:if>
        <xsl:if test="genus and species">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="species">
            <text:span text:style-name="Species">
                <xsl:apply-templates select="species"/>
            </text:span>
        </xsl:if>
    </text:span>
</xsl:template>
<xsl:template match="email">
    <text:span text:style-name="Email">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>

<!-- ########## -->
<!-- Characters -->
<!-- ########## -->
<xsl:template name="lsq-character">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>
<xsl:template name="rsq-character">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>
<xsl:template name="lq-character">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>
<xsl:template name="rq-character">
    <xsl:text>&#x201d;</xsl:text>
</xsl:template>
<xsl:template name="ldblbracket-character">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>
<xsl:template name="rdblbracket-character">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>
<xsl:template name="langle-character">
    <xsl:text>&#x3008;</xsl:text>
</xsl:template>
<xsl:template name="rangle-character">
    <xsl:text>&#x3009;</xsl:text>
</xsl:template>
<xsl:template name="nbsp-character">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>
<xsl:template name="ndash-character">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>
<xsl:template name="mdash-character">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>
<xsl:template name="midpoint-character">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>
<xsl:template name="swungdash-character">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>
<xsl:template name="permille-character">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>
<xsl:template name="pilcrow-character">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>
<xsl:template name="section-mark-character">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>
<xsl:template name="minus-character">
    <xsl:text>&#x2212;</xsl:text>
</xsl:template>
<xsl:template name="times-character">
    <xsl:text>&#xd7;</xsl:text>
</xsl:template>
<xsl:template name="solidus-character">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>
<xsl:template name="obelus-character">
    <xsl:text>&#xf7;</xsl:text>
</xsl:template>
<xsl:template name="plusminus-character">
    <xsl:text>&#xb1;</xsl:text>
</xsl:template>
<xsl:template name="copyright-character">
    <xsl:text>&#xa9;</xsl:text>
</xsl:template>
<!-- Registered symbol -->
<!-- Bringhurst: should be superscript                    -->
<!-- We consider it a font mistake if not superscripted,  -->
<!-- since if we use a "sup" tag then a correct font will -->
<!-- get way too small                                    -->
<xsl:template name="registered-character">
    <xsl:text>&#xae;</xsl:text>
</xsl:template>
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->
<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>
    <!-- for-each is just one node, but sets context for key() -->
    <xsl:variable name="unicode">
        <xsl:for-each select="$icon-table">
            <xsl:value-of select="key('icon-key', $icon-name)/@unicode"/>
        </xsl:for-each>
    </xsl:variable>
    <text:span text:style-name="Icon">
        <xsl:value-of select="$unicode"/>
    </text:span>
</xsl:template>

<!-- ########## -->
<!-- Generators -->
<!-- ########## -->
<xsl:template match="tex">
    <text:span text:style-name="TeX">T<text:span text:style-name="E">E</text:span>X</text:span>
</xsl:template>
<xsl:template match="latex">
    <text:span text:style-name="TeX">L<text:span text:style-name="A">A</text:span>T<text:span text:style-name="E">E</text:span>X</text:span>
</xsl:template>

<!-- ###### -->
<!-- Fillin -->
<!-- ###### -->
<xsl:template match="fillin">
    <!-- TODO: using a string of nbsp with styled underlining does not make an accessible fillin -->
    <text:span text:style-name="Fillin">
        <xsl:call-template name="duplicate-string">
            <xsl:with-param name="text">
                <xsl:call-template name="nbsp-character"/>
            </xsl:with-param>
            <xsl:with-param name="count" select="@characters" />
        </xsl:call-template>
    </text:span>
</xsl:template>

<!-- ######## -->
<!-- Footnote -->
<!-- ######## -->
<xsl:template match="fn">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:variable name="citation">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <text:note text:id="{$id}" text:note-class="footnote">
        <text:note-citation>
            <xsl:value-of select="$citation" />
        </text:note-citation>
        <text:note-body>
            <text:p text:style-name="Footnote">
                <xsl:apply-templates />
            </text:p>
        </text:note-body>
    </text:note>
</xsl:template>

<!-- ######## -->
<!-- SI Units -->
<!-- ######## -->
<xsl:template match="quantity">
    <!-- TODO: We would like this span to prevent line breaks within the quantity -->
    <text:span text:style-name="Quantity">
        <xsl:apply-templates select="mag"/>
        <!-- if not solo, add separation -->
        <xsl:if test="mag and (unit or per)">
            <xsl:call-template name="nbsp-character" />
        </xsl:if>
        <xsl:choose>
            <xsl:when test="per">
                <xsl:if test="not(unit)">
                    <xsl:text>1</xsl:text>
                </xsl:if>
                <xsl:apply-templates select="unit" />
                <xsl:call-template name="solidus-character" />
                <xsl:apply-templates select="per" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="unit"/>
            </xsl:otherwise>
        </xsl:choose>
    </text:span>
</xsl:template>
<xsl:template match="mag">
    <xsl:variable name="mag">
        <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:value-of select="str:replace($mag,'\pi','&#x1D70B;')"/>
</xsl:template>
<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->
<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>
<xsl:template match="unit|per">
    <!-- add dot within a product of units -->
    <xsl:if test="(self::unit and preceding-sibling::unit) or (self::per and preceding-sibling::per)">
        <xsl:call-template name="midpoint-character" />
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('pretext-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is required -->
    <xsl:variable name="base">
        <xsl:value-of select="@base" />
    </xsl:variable>
    <xsl:variable name="short">
        <xsl:for-each select="document('pretext-units.xsl')">
            <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="$short" />
     <!-- exponent is optional -->
    <xsl:if test="@exp">
        <text:span text:style-name="Exponent">
            <xsl:value-of select="@exp"/>
        </text:span>
    </xsl:if>
</xsl:template>

<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->
<!-- .odt will (1) ignore leading and trailing whitespace -->
<!-- (2) collapse adjacent whitespace into a single space -->
<!-- (3) treat a line break character as a space          -->
<!-- So the explicit-space template replaces space with   -->
<!-- <text:s/> and replaces \n with <text:line-break/>    -->
<!-- With pre, we still past conteent to sanitize-text    -->
<!-- template for consistency with other output formats   -->

<!-- TODO: code spans will line break in the natural way, and I'm unsure if it's possible to prevent that.        -->
<!-- With line breaking possible, an outline makes less sense; can't seem to get an outline even if I wanted one. -->
<xsl:template match="c">
    <text:span text:style-name="C">
        <xsl:call-template name="explicit-space">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </text:span>
</xsl:template>

<xsl:template match="cd">
    <xsl:if test="preceding-sibling::* or preceding-sibling::text()[normalize-space() != '']">
        <text:line-break/>
    </xsl:if>
    <text:span text:style-name="C">
        <xsl:choose>
            <xsl:when test="cline">
                <xsl:apply-templates select="cline" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="explicit-space">
                    <xsl:with-param name="string" select="."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </text:span>
    <xsl:if test="following-sibling::* or following-sibling::text()[normalize-space() != '']">
        <text:line-break/>
    </xsl:if>
</xsl:template>

<xsl:template match="cline">
    <xsl:call-template name="explicit-space">
        <xsl:with-param name="string" select="."/>
    </xsl:call-template>
    <xsl:if test="following-sibling::cline">
        <text:line-break/>
    </xsl:if>
</xsl:template>

<xsl:template match="pre">
    <text:p text:style-name="Pre">
        <xsl:choose>
            <xsl:when test="cline">
                <xsl:apply-templates select="cline" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="explicit-space">
                    <xsl:with-param name="string">
                        <xsl:call-template name="sanitize-text">
                            <xsl:with-param name="text" select="." />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </text:p>
</xsl:template>

<xsl:template name="explicit-space">
    <xsl:param name="string" select="''"/>
    <xsl:choose>
        <xsl:when test="string-length($string) = 0"/>
        <xsl:when test="substring($string,1,1) = ' '">
            <text:s/>
            <xsl:call-template name="explicit-space">
                <xsl:with-param name="string" select="substring($string,2)"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="substring($string,1,1) = '&#xa;'">
            <text:line-break/>
            <xsl:call-template name="explicit-space">
                <xsl:with-param name="string" select="substring($string,2)"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="substring($string,1,1)" />
            <xsl:call-template name="explicit-space">
                <xsl:with-param name="string" select="substring($string,2)"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ### -->
<!-- URL -->
<!-- ### -->
<xsl:template match="url">
    <!-- visible portion of HTML is the URL itself,   -->
    <!-- formatted as code, or content of PTX element -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="not(*) and not(normalize-space())">
                <xsl:variable name="the-element">
                    <c>
                        <xsl:value-of select="@href" />
                    </c>
                </xsl:variable>
                <xsl:apply-templates select="exsl:node-set($the-element)/*" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Normally in an active link, except inactive in titles -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:copy-of select="$visible-text" />
        </xsl:when>
        <xsl:otherwise>
            <!-- class name identifies an external link -->
            <text:a xlink:type="simple" xlink:href="{@href}">
                <xsl:copy-of select="$visible-text" />
            </text:a>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Cross-references -->
<!-- ################ -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:param name="xref" />
    <xsl:param name="b-human-readable" />
    <xsl:copy-of select="$content" />
</xsl:template>

<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->
<xsl:template match="ol">
    <text:list>
        <xsl:attribute name="text:style-name">
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:apply-templates select="." mode="get-label"/>
                </xsl:when>
                <xsl:when test="ancestor::exercise">
                    <xsl:text>Exercises</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>List</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates />
    </text:list>
</xsl:template>

<xsl:template match="ol" mode="get-label">
    <xsl:choose>
        <xsl:when test="contains(@label,'0')">
            <xsl:message>PTX:ERROR: .odt output format does not permit list numbering to begin with 0</xsl:message>
        </xsl:when>
        <xsl:when test="contains(@label,'1')">Arabic-1</xsl:when>
        <xsl:when test="contains(@label,'a')">Lowercase</xsl:when>
        <xsl:when test="contains(@label,'A')">Uppercase</xsl:when>
        <xsl:when test="contains(@label,'i')">Lowercase-roman</xsl:when>
        <xsl:when test="contains(@label,'I')">Uppercase-roman</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: ordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="." mode="list-level"/>
</xsl:template>

<xsl:template match="ul">
    <text:list>
        <xsl:attribute name="text:style-name">
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:apply-templates select="." mode="get-label"/>
                </xsl:when>
                <xsl:when test="ancestor::exercise">
                    <xsl:text>Exercises-unordered</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Unordered</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates />
    </text:list>
</xsl:template>

<xsl:template match="ul" mode="get-label">
    <xsl:choose>
        <xsl:when test="@label='disc'">Disc</xsl:when>
        <xsl:when test="@label='circle'">Circle</xsl:when>
        <xsl:when test="@label='square'">Square</xsl:when>
        <xsl:when test="@label=''">None</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: unordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="." mode="list-level"/>
</xsl:template>

<xsl:template match="dl">
    <text:list>
        <xsl:attribute name="text:style-name">
            <xsl:apply-templates select="." mode="get-label"/>
        </xsl:attribute>
        <xsl:apply-templates />
    </text:list>
</xsl:template>

<xsl:template match="dl" mode="get-label">
    <xsl:text>Description-</xsl:text>
    <xsl:apply-templates select="." mode="list-level"/>
</xsl:template>

<xsl:template match="li">
    <text:list-item>
        <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
        <xsl:if test="title and *[not(&METADATA-FILTER;)][position() = 1][not(self::p)]">
            <text:p text:style-name="P">
                <text:span text:style-name="Runin-title">
                    <xsl:apply-templates select="." mode="title-full"/>
                </text:span>
            </text:p>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="p|blockquote|pre|figure|table|listing|list|aside|biographical|historical|sidebyside|sbsgroup|sage">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <text:p>
                    <xsl:attribute name="text:style-name">
                        <xsl:choose>
                            <xsl:when test="following-sibling::*|parent::li/following-sibling::li|ancestor::ol/following-sibling::*|ancestor::ol/parent::p/following-sibling::*|ancestor::ul/following-sibling::*|ancestor::ul/parent::p/following-sibling::*|ancestor::dl/following-sibling::*|ancestor::dl/parent::p/following-sibling::*">
                                <xsl:text>P</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>P-last</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </text:p>
            </xsl:otherwise>
        </xsl:choose>
    </text:list-item>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->
<xsl:template match="m">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <draw:frame
        draw:style-name="Inline-math"
        draw:name="Object-{$id}"
        svg:y="0.172in"
        >
        <draw:object
            xlink:href="./Object-{$id}"
            xlink:type="simple"
        />
    </draw:frame>
    <xsl:variable name="folder">
        <xsl:apply-templates select="ancestor::worksheet" mode="folder"/>
    </xsl:variable>
    <!-- Note: exsl:document is already writing to the folder for this worksheet, -->
    <!-- so file paths used here for the math object files are relative to that.  -->
    <xsl:variable name="contentfilepathname" select="concat('Object-',$id,'/content.xml')" />
    <xsl:variable name="math-mml" select="$math-mml-repr/pi:math[@id = $id]/div/math:math/math:*"/>
    <xsl:variable name="math-svg" select="$math-svg-repr/pi:math[@id = $id]/div/*"/>
    <xsl:variable name="math-speech" select="$math-speech-repr/pi:math[@id = $id]/div/text()"/>
    <exsl:document href="{$contentfilepathname}" method="xml" version="1.0">
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE math PUBLIC "-//W3C//DTD MathML 3.0//EN" "http://www.w3.org/Math/DTD/mathml2/mathml2.dtd"&gt;&#xa;</xsl:text>
        <math xmlns="http://www.w3.org/1998/Math/MathML">
            <xsl:text>&#xa;  </xsl:text>
            <xsl:apply-templates select="$math-mml" mode="copy"/>
        </math>
    </exsl:document>
    <xsl:variable name="settingsfilepathname" select="concat('Object-',$id,'/settings.xml')" />
    <exsl:document href="{$settingsfilepathname}" method="xml" version="1.0">
        <office:document-settings office:version="1.3" />
    </exsl:document>
</xsl:template>

<xsl:template match="me|md">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <text:p text:style-name="P-display">
        <draw:frame
            draw:style-name="Display-math"
            draw:name="Object-{$id}"
            svg:y="0.172in"
            >
            <draw:object
                xlink:href="./Object-{$id}"
                xlink:type="simple"
            />
        </draw:frame>
    </text:p>
    <xsl:variable name="folder">
        <xsl:apply-templates select="ancestor::worksheet" mode="folder"/>
    </xsl:variable>
    <!-- Note: exsl:document is already writing to the folder for this worksheet, -->
    <!-- so file paths used here for the math object files are relative to that.  -->
    <xsl:variable name="contentfilepathname" select="concat('Object-',$id,'/content.xml')" />
    <xsl:variable name="math-mml" select="$math-mml-repr/pi:math[@id = $id]/div/math:math/math:*"/>
    <xsl:variable name="math-svg" select="$math-svg-repr/pi:math[@id = $id]/div/*"/>
    <xsl:variable name="math-speech" select="$math-speech-repr/pi:math[@id = $id]/div/text()"/>
    <exsl:document href="{$contentfilepathname}" method="xml" version="1.0">
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE math PUBLIC "-//W3C//DTD MathML 3.0//EN" "http://www.w3.org/Math/DTD/mathml3/mathml3.dtd"&gt;&#xa;</xsl:text>
        <math xmlns="http://www.w3.org/1998/Math/MathML">
            <xsl:text>&#xa;  </xsl:text>
            <xsl:apply-templates select="$math-mml" mode="copy"/>
        </math>
    </exsl:document>
    <xsl:variable name="settingsfilepathname" select="concat('Object-',$id,'/settings.xml')" />
    <exsl:document href="{$settingsfilepathname}" method="xml" version="1.0">
        <office:document-settings office:version="1.3" />
    </exsl:document>
</xsl:template>

<!-- essentially copy-of, but without copying namespace nodes   -->
<!-- or the data-mjx- attributes (for MathML schema compliance) -->
<xsl:template match="*" mode="copy">
  <xsl:element name="{name()}" namespace="{namespace-uri()}">
    <xsl:apply-templates select="@*[not(substring(name(),1,9) = 'data-mjx-')]|node()" mode="copy" />
  </xsl:element>
</xsl:template>

<xsl:template match="@*|text()|comment()" mode="copy">
  <xsl:copy/>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->
<xsl:template match="image">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:variable name="width" select="($layout/width) div 100 * $design-text-width"/>
    <xsl:variable name="extension">
        <xsl:apply-templates select="." mode="extension" />
    </xsl:variable>
    <xsl:variable name="type">
        <xsl:apply-templates select="." mode="media-type" />
    </xsl:variable>
    <text:p
        text:style-name="P-display"
        >
        <!-- TODO: this sets image height to 1 inch, all the time.           -->
        <!-- We need to use external tools to get each image's actual height -->
        <!-- (relative to the declared width) and use that instead.          -->
        <draw:frame
            draw:style-name="Image"
            draw:name="{$id}"
            svg:width="{$width}{$design-unit}"
            svg:height="1in"
            text:anchor-type="as-char"
            >
            <!-- draw:z-index="0" -->
            <draw:image
                xlink:href="images/{$id}.{$extension}"
                xlink:type="simple"
                xlink:show="embed"
                xlink:actuate="onLoad"
                draw:mime-type="{$type}"
            />
        </draw:frame>
    </text:p>
</xsl:template>

<xsl:template match="image" mode="extension">
    <xsl:choose>
        <xsl:when test="@source">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename" select="@source" />
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="latex-image|sageplot|asymptote">
            <xsl:text>png</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="image" mode="media-type">
    <xsl:choose>
        <xsl:when test="@source">
            <xsl:variable name="extension">
                <xsl:call-template name="file-extension">
                    <xsl:with-param name="filename" select="@source" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <!-- defatult to png -->
                <xsl:when test="$extension = ''">
                    <xsl:text>image/png</xsl:text>
                </xsl:when>
                <xsl:when test="$extension = 'png'">
                    <xsl:text>image/png</xsl:text>
                </xsl:when>
                <xsl:when test="$extension = 'pdf'">
                    <xsl:text>application/pdf</xsl:text>
                </xsl:when>
                <xsl:when test="$extension = 'svg'">
                    <xsl:text>image/svg+xml</xsl:text>
                </xsl:when>
                <xsl:when test="$extension = 'jpg'">
                    <xsl:text>image/jpeg</xsl:text>
                </xsl:when>
                <xsl:when test="$extension = 'jpeg'">
                    <xsl:text>image/jpeg</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   file extension of file with source <xsl:value-of select="@source"/> not recognized.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="latex-image|sageplot|asymptote">
            <xsl:text>image/png</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR:   unable to determine media type for image with visible id <xsl:apply-templates select="." mode="visible-id"/>.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ####### -->
<!-- Tabular -->
<!-- ####### -->
<!--
    margins.
    width control (It's just line width divided equally among columns).
    headers.
    paragraph cells.
-->
<!-- Modeled after HTML -->
<xsl:template match="tabular[not(ancestor::sidebyside)]">
    <text:p
        text:style-name="P-display"
        >
        <xsl:variable name="width">
            <xsl:apply-templates select="." mode="get-line-width"/>
        </xsl:variable>
        <draw:frame
            draw:style-name="Tabular-wrapper"
            text:anchor-type="as-char"
            svg:width="{$width}{$design-unit}"
            draw:z-index="0"
            >
            <draw:text-box fo:min-height="0in">
                <xsl:apply-templates select="." mode="tabular-inclusion">
                    <xsl:with-param name="width" select="'100%'" />
                </xsl:apply-templates>
            </draw:text-box>
        </draw:frame>
    </text:p>
</xsl:template>

<xsl:template match="tabular" mode="tabular-inclusion">
    <xsl:param name="width" select="$width"/>
    <!-- Abort if tabular's cols have widths summing to over 100% -->
    <xsl:call-template name="cap-width-at-one-hundred-percent">
        <xsl:with-param name="nodeset" select="col/@width" />
    </xsl:call-template>
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <!-- NB: table styles seem ineffective in styles.xml, but are effective in context.xml as automatic styles -->
    <table:table table:name="{$id}" table:style-name="{$id}">
        <xsl:apply-templates select="." mode="columns"/>
        <!-- We *actively* enforce header rows being (a) initial, and      -->
        <!-- (b) contiguous.  So following two-part match will do no harm  -->
        <!-- to correct source, but will definitely harm incorrect source. -->
        <xsl:apply-templates select="row[@header]">
            <xsl:with-param name="ambient-relative-width" select="$width" />
        </xsl:apply-templates>
        <xsl:apply-templates select="row[not(@header)]">
            <xsl:with-param name="ambient-relative-width" select="$width" />
        </xsl:apply-templates>
    </table:table>
</xsl:template>

<xsl:template match="tabular" mode="columns">
    <xsl:variable name="col-count">
        <xsl:apply-templates select="." mode="get-column-count"/>
    </xsl:variable>
    <table:table-column
        table:number-columns-repeated="{$col-count}"
    />
</xsl:template>

<!-- A row of table -->
<xsl:template match="row">
    <xsl:param name="ambient-relative-width" />
    <!-- Form the ODT table row -->
    <table:table-row>
        <!-- Walk the cells of the row -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="ambient-relative-width">
                <xsl:value-of select="$ambient-relative-width" />
            </xsl:with-param>
            <xsl:with-param name="the-cell" select="cell[1]" />
            <xsl:with-param name="left-col" select="ancestor::tabular/col[1]" />  <!-- possibly empty -->
        </xsl:call-template>
    </table:table-row>
</xsl:template>

<xsl:template name="row-cells">
    <xsl:param name="ambient-relative-width" />
    <xsl:param name="the-cell" />
    <xsl:param name="left-col" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the col elements          -->
    <!-- for the left and right ends of the span                            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
    <xsl:variable name="column-span">
        <xsl:choose>
            <xsl:when test="$the-cell/@colspan">
                <xsl:value-of select="$the-cell/@colspan" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- For a "normal" 1-column cell this variable effectively makes a copy -->
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
    <!-- Look ahead one column, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells) -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" />
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" /> <!-- possibly empty -->
    <xsl:if test="$the-cell">
        <!-- build an ODT cell                                          -->
        <!-- we set properties in various variables,                    -->
        <!-- then write them as attributes                              -->
        <!-- Some properties belong in the style, not here              -->
        <xsl:variable name="col">
            <xsl:apply-templates select="$the-cell/parent::row" mode="get-column-count">
                <xsl:with-param name="up-to-cell" select="count($the-cell/preceding-sibling::cell) + 1"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="row" select="count($the-cell/parent::row/preceding-sibling::row) + 1"/>
        <xsl:variable name="name">
            <xsl:apply-templates select="ancestor::tabular" mode="visible-id"/>
            <xsl:text>.</xsl:text>
            <xsl:value-of select="substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ', $col, 1)"/>
            <xsl:value-of select="$row"/>
        </xsl:variable>
        <!-- the element for the cell -->
        <table:table-cell table:style-name="{$name}" office:value-type="string">
            <xsl:if test="$column-span > 1">
                <xsl:attribute name="table:number-columns-spanned">
                    <xsl:value-of select="$column-span" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$the-cell/p">
                <xsl:attribute name="style">
                    <xsl:text>max-width:</xsl:text>
                    <xsl:choose>
                        <xsl:when test="$left-col/@width">
                            <xsl:variable name="width">
                                <xsl:call-template name="normalize-percentage">
                                    <xsl:with-param name="percentage" select="$left-col/@width" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:value-of select="$design-width * substring-before($width, '%') div 100 * substring-before($ambient-relative-width, '%') div 100" />
                            <xsl:text>px;</xsl:text>
                        </xsl:when>
                        <!-- If there is no $left-col/@width, terminate -->
                        <xsl:otherwise>
                            <xsl:message>MBX:FATAL:   cell with a "p" element has no corresponding col element with width attribute.</xsl:message>
                            <xsl:apply-templates select="." mode="location-report" />
                            <xsl:message terminate="yes">Quitting...</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <!-- process the actual contents           -->
            <!-- condition on indicators of structure  -->
            <!-- All "line", all "p", or mixed content -->
            <!-- TODO: is it important to pass $b-original -->
            <!-- flag into template for "line" elements?   -->
            <xsl:choose>
                <xsl:when test="$the-cell/p">
                    <xsl:apply-templates select="$the-cell/p"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$the-cell"/>
                </xsl:otherwise>
            </xsl:choose>
        </table:table-cell>
        <!-- need to have "covered cells" if there was a colspan > 1 -->
        <xsl:call-template name="covered-cells">
            <xsl:with-param name="count" select="$column-span - 1"/>
        </xsl:call-template>
        <!-- recurse forward, perhaps to an empty cell -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="ambient-relative-width" select="$ambient-relative-width" />
            <xsl:with-param name="the-cell" select="$next-cell" />
            <xsl:with-param name="left-col" select="$next-col" />
        </xsl:call-template>
    </xsl:if>
    <!-- Arrive here only when we have no cell so      -->
    <!-- we bail out of recursion with no action taken -->
</xsl:template>

<xsl:template name="covered-cells">
    <xsl:param name="count"/>
    <xsl:if test="$count > 0">
        <table:covered-table-cell/>
        <xsl:call-template name="covered-cells">
            <xsl:with-param name="count" select="$count - 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template match="tabular/row/cell">
    <xsl:variable name="col">
        <xsl:apply-templates select="parent::row" mode="get-column-count">
            <xsl:with-param name="up-to-cell" select="count(preceding-sibling::cell) + 1"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="alignment">
        <xsl:text>-</xsl:text>
        <xsl:choose>
            <!-- cell attribute first -->
            <xsl:when test="@halign">
                <xsl:value-of select="@halign" />
            </xsl:when>
            <!-- parent row attribute next -->
            <xsl:when test="parent::row/@halign">
                <xsl:value-of select="parent::row/@halign" />
            </xsl:when>
            <!-- col attribute next -->
            <xsl:when test="ancestor::tabular/col[$col]/@halign">
                <xsl:value-of select="ancestor::tabular/col[$col]/@halign" />
            </xsl:when>
            <!-- table attribute last -->
            <xsl:when test="ancestor::tabular/@halign">
                <xsl:value-of select="ancestor::tabular/@halign" />
            </xsl:when>
            <!-- HTML default is left, we write it for consistency -->
            <xsl:otherwise>
                <xsl:text>left</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="header">
        <!-- NB: I'm only able to get vertical headers if I use a LibreOffice extension -->
        <!-- making the ODT not conform to spec. So we don't do this, and warn.         -->
        <xsl:choose>
            <xsl:when test="parent::row/@header = 'yes'">
                <xsl:text>-header</xsl:text>
            </xsl:when>
            <xsl:when test="parent::row/@header = 'vertical'">
                <xsl:message>PTX:WARNING: Unable to construct vertical table headers. Proceeding with horizontal headers.&#xa;</xsl:message>
                <xsl:text>-header</xsl:text>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="p">
            <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
            <text:p>
                <xsl:attribute name="text:style-name">
                    <xsl:value-of select="concat('P',$alignment,$header)"/>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="line">
                        <xsl:apply-templates select="line"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates/>
                    </xsl:otherwise>
                </xsl:choose>
            </text:p>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="tabular/row/cell/line">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::line">
        <text:line-break/>
    </xsl:if>
</xsl:template>

<xsl:template match="tabular" mode="get-column-count">
    <xsl:param name="lower-bound" select="1"/>
    <xsl:param name="row" select="1"/>    
    <xsl:choose>
        <!-- terminate if there are col elements we can just count -->
        <xsl:when test="col">
            <xsl:value-of select="count(col)"/>
        </xsl:when>
        <!-- if we have recursed to the last row, terminate -->
        <xsl:when test="$row > count(row)">
            <xsl:value-of select="$lower-bound"/>
        </xsl:when>
        <!-- recurse to the next row -->
        <xsl:otherwise>
            <xsl:variable name="this-row-col-count">
                <xsl:apply-templates select="row[$row]" mode="get-column-count"/>
            </xsl:variable>
            <xsl:apply-templates select="." mode="get-column-count">
                <xsl:with-param name="lower-bound">
                    <xsl:choose>
                        <xsl:when test="$this-row-col-count > $lower-bound">
                            <xsl:value-of select="$this-row-col-count"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$lower-bound"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="row" select="$row + 1"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="row" mode="get-column-count">
    <xsl:param name="running-count" select="0"/>
    <xsl:param name="cell" select="1"/>
    <xsl:param name="up-to-cell" select="count(cell)"/>
    <xsl:choose>
        <!-- terminate if we have recursed to the last cell -->
        <xsl:when test="$cell > $up-to-cell">
            <xsl:value-of select="$running-count"/>
        </xsl:when>
        <!-- recurse to the next cell -->
        <xsl:otherwise>
            <xsl:variable name="cell-colspan">
                <xsl:apply-templates select="cell[$cell]" mode="get-column-count"/>
            </xsl:variable>
            <xsl:apply-templates select="." mode="get-column-count">
                <xsl:with-param name="running-count" select="$running-count + $cell-colspan"/>
                <xsl:with-param name="cell" select="$cell + 1"/>
                <xsl:with-param name="up-to-cell" select="$up-to-cell"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="cell" mode="get-column-count">
    <xsl:choose>
        <xsl:when test="@colspan">
            <xsl:value-of select="@colspan"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="1"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->
<!-- Find the absolute width of the ambient line -->
<xsl:template match="*" mode="get-line-width">
    <xsl:choose>
        <xsl:when test="not(ancestor::exercise) and not(ancestor::sidebyside)">
            <xsl:value-of select="$design-text-width"/>
        </xsl:when>
        <xsl:when test="ancestor::exercise and not(ancestor::sidebyside)">
            <xsl:value-of select="$design-text-width - $design-indent"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- ############# -->
<!-- File building -->
<!-- ############# -->
<!-- Append a filename to the directory path              -->
<xsl:template match="worksheet" mode="folder">
    <xsl:text>worksheets/</xsl:text>
    <xsl:apply-templates select="." mode="numbered-title-filesafe" />
    <xsl:text>/</xsl:text>
</xsl:template>

<!-- mimetype -->
<!-- Considered using a named template, but maybe something -->
<!-- else in the future will need a different mimetype      -->
<xsl:template match="worksheet" mode="mimetype">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'mimetype')" />
    <exsl:document href="{$filepathname}" method="text">
        <xsl:text>application/vnd.oasis.opendocument.text</xsl:text>
    </exsl:document>
</xsl:template>

<!-- styles.xml -->
<!-- Defines styles quasi-analogously to a .css file for HTML -->
<xsl:template match="worksheet" mode="styles">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'styles.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-styles
            office:version="1.3"
            xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
            >
            <office:font-face-decls>
                <style:font-face
                    style:name="Main"
                    svg:font-family="&apos;Latin Modern Roman&apos;"
                    style:font-family-generic="roman"
                    style:font-pitch="variable"
                />
                <xsl:if test=".//tex|.//latex">
                    <style:font-face
                        style:name="TeX"
                        svg:font-family="&apos;Latin Modern Roman&apos;"
                        style:font-family-generic="roman"
                    />
                </xsl:if>
                <xsl:if test=".//icon">
                    <style:font-face
                        style:name="Icon"
                        svg:font-family="&apos;Arial Unicode MS&apos;"
                        style:font-family-generic="decorative"
                        style:font-pitch="variable"
                    />
                </xsl:if>
                <xsl:if test=".//c|.//cd|.//tag|.//tage|.//attr|.//url">
                    <style:font-face
                        style:name="Code"
                        svg:font-family="&apos;Courier New&apos;"
                        style:font-family-generic="modern"
                        style:font-pitch="fixed"
                    />
                </xsl:if>
            </office:font-face-decls>
            <office:styles>
                <style:default-style style:family="paragraph">
                    <!-- We are unable to use paragraphindentation in a consistent way throughout a worksheet, -->
                    <!-- including within exercises. So we use no indenation anywhere and end a paragraph with -->
                    <!-- 0.08304in (6pt) of vertical skip as a way to indicate new paragraphs.                 -->
                    <style:paragraph-properties
                        fo:orphans="2"
                        fo:widows="2"
                        style:auto-text-indent="false"
                        style:punctuation-wrap="hanging"
                    />
                    <style:text-properties
                        style:font-name="Main"
                        fo:font-size="12pt"
                        style:letter-kerning="true"
                    />
                </style:default-style>
                <style:default-style
                    style:family="graphic"
                />
                <style:default-style
                    style:family="table"
                    >
                    <style:table-properties
                        table:border-model="collapsing"
                    />
                </style:default-style>
                <style:default-style
                    style:family="table-row"
                    >
                    <style:table-row-properties
                        fo:keep-together="auto"
                    />
                </style:default-style>
                <!-- A typical paragraph -->
                <style:style
                    style:name="P"
                    style:family="paragraph"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.08304in"
                        fo:text-indent="0in"
                    />
                </style:style>
                <!-- This style is for when a PTX p is broken up into -->
                <!-- several ODT p because of a list or display       -->
                <style:style
                    style:name="P-fragment"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0in"
                    />
                </style:style>
                <!-- The last paragraph in a block can have a bit more vertical skip at the end -->
                <style:style
                    style:name="P-last"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.16608in"
                    />
                </style:style>
                <!-- Paragraph style for centered displayed items -->
                <style:style
                    style:name="P-display"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.08304in"
                        fo:text-indent="0in"
                        fo:text-align="center"
                    />
                </style:style>
                <!-- Styles for p's within table cells -->
                <style:style
                    style:name="P-left"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                        fo:text-align="left"
                    />
                </style:style>
                <style:style
                    style:name="P-center"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                        fo:text-align="center"
                    />
                </style:style>
                <style:style
                    style:name="P-right"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                        fo:text-align="right"
                    />
                </style:style>
                <style:style
                    style:name="P-left-header"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                        fo:text-align="left"
                    />
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <style:style
                    style:name="P-center-header"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                        fo:text-align="center"
                    />
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <style:style
                    style:name="P-right-header"
                    style:family="paragraph"
                    style:next-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                        fo:text-align="right"
                    />
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Decorate a run-in title -->
                <style:style
                    style:name="Runin-title"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Groupings -->
                <xsl:if test=".//abbr">
                    <style:style
                        style:name="Abbr"
                        style:family="text"
                    />
                </xsl:if>
                <xsl:if test=".//acro">
                    <style:style
                        style:name="Acro"
                        style:family="text"
                    />
                </xsl:if>
                <xsl:if test=".//init">
                    <style:style
                        style:name="Init"
                        style:family="text"
                    />
                </xsl:if>
                <xsl:if test=".//em">
                    <style:style
                        style:name="Emphasis"
                        style:family="text"
                        >
                        <style:text-properties
                            fo:font-style="italic"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//term">
                    <style:style
                        style:name="Term"
                        style:family="text"
                        >
                        <style:text-properties
                            fo:font-weight="bold"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//alert">
                    <style:style
                        style:name="Alert"
                        style:family="text"
                        >
                        <style:text-properties
                            fo:font-style="italic"
                            fo:font-weight="bold"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//pubtitle">
                    <style:style
                        style:name="Pubtitle"
                        style:family="text"
                        >
                        <style:text-properties
                            fo:font-style="oblique"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//articletitle">
                    <style:style
                        style:name="Articletitle"
                        style:family="text"
                        >
                    </style:style>
                </xsl:if>
                <xsl:if test=".//foreign">
                    <style:style
                        style:name="Foreign"
                        style:family="text"
                        >
                        <style:text-properties
                            fo:font-style="italic"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//delete">
                    <style:style
                        style:name="Delete"
                        style:family="text"
                        >
                        <style:text-properties
                            style:text-line-through-style="solid"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//insert">
                    <style:style
                        style:name="Insert"
                        style:family="text"
                        >
                        <style:text-properties
                            style:text-underline-style="solid"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//stale">
                    <style:style
                        style:name="Stale"
                        style:family="text"
                        >
                        <style:text-properties
                            style:text-line-through-style="solid"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//taxon">
                    <style:style
                        style:name="Taxon"
                        style:family="text"
                        >
                        <style:text-properties
                            fo:font-style="italic"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//genus">
                    <style:style
                        style:name="Genus"
                        style:family="text"
                        >
                        <style:text-properties
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//species">
                    <style:style
                        style:name="Species"
                        style:family="text"
                        >
                        <style:text-properties
                        />
                    </style:style>
                    <style:style
                        style:name="Email"
                        style:family="text"
                    />
                </xsl:if>
                <!-- Icons -->
                <xsl:if test=".//icon">
                    <style:style
                        style:name="Icon"
                        style:family="text"
                        >
                        <style:text-properties
                            style:font-name="Icon"
                        />
                    </style:style>
                </xsl:if>
                <!-- Generators -->
                <xsl:if test=".//tex|.//latex">
                    <style:style
                        style:name="TeX"
                        style:family="text"
                        >
                        <style:text-properties
                            style:font-name="TeX"
                            fo:letter-spacing="-0.01951in"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//tex|.//latex">
                    <style:style
                        style:name="E"
                        style:family="text"
                        style:parent-style-name="TeX"
                        >
                        <style:text-properties
                            style:text-position="-21.5% 100%"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//latex">
                    <style:style
                        style:name="A"
                        style:family="text"
                        style:parent-style-name="TeX"
                        >
                        <style:text-properties
                            style:text-position="21.5% 75%"
                        />
                    </style:style>
                </xsl:if>
                <!-- Fillin -->
                <xsl:if test=".//fillin">
                    <style:style
                        style:name="Fillin"
                        style:family="text"
                        >
                        <style:text-properties
                            style:text-underline-style="solid"
                            style:text-underline-width="auto"
                            style:text-underline-color="font-color"
                        />
                    </style:style>
                </xsl:if>
                <!-- Quantity -->
                <xsl:if test=".//quantity">
                    <style:style
                        style:name="Quantity"
                        style:family="text"
                    />
                    <style:style
                        style:name="Super"
                        style:family="text"
                        >
                        <style:text-properties
                            style:text-position="super"
                        />
                    </style:style>
                </xsl:if>
                <!-- Verbatim -->
                <xsl:if test=".//c">
                    <style:style
                        style:name="C"
                        style:family="text"
                        >
                        <style:text-properties
                            style:font-name="Code"
                            fo:background-color="#eeeeee"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//cd">
                    <style:style
                        style:name="Cd"
                        style:display-name="Code Display"
                        style:family="paragraph"
                        >
                        <style:text-properties
                            style:font-name="Code"
                            fo:background-color="#eeeeee"
                        />
                    </style:style>
                </xsl:if>
                <xsl:if test=".//pre">
                    <style:style
                        style:name="Pre"
                        style:display-name="Preformatted"
                        style:family="paragraph"
                        >
                        <style:text-properties
                            style:font-name="Code"
                        />
                    </style:style>
                </xsl:if>
                <!-- Footnote -->
                <xsl:if test=".//fn">
                    <style:style
                        style:name="Footnote"
                        style:family="paragraph"
                        style:parent-style-name="P"
                        >
                        <style:paragraph-properties
                            fo:margin-left="0.2354in"
                            fo:margin-right="0in"
                            fo:text-indent="-0.2354in"
                            style:auto-text-indent="false"
                            text:number-lines="false"
                            text:line-number="0"
                        />
                        <style:text-properties
                            fo:font-size="10pt"
                        />
                    </style:style>
                </xsl:if>
                <!-- Math -->
                <style:style
                    style:name="Formula"
                    style:family="graphic"
                />
                <style:style
                    style:name="Inline-math"
                    style:family="graphic"
                    style:parent-style-name="Formula"
                    >
                    <style:graphic-properties
                        style:vertical-pos="below"
                        text:anchor-type="as-char"
                    />
                </style:style>
                <style:style
                    style:name="Display-math"
                    style:family="graphic"
                    style:parent-style-name="Formula"
                    >
                    <style:graphic-properties
                        style:vertical-pos="below"
                        text:anchor-type="paragraph"
                    />
                </style:style>
                <!-- Images -->
                <style:style
                    style:name="Graphics"
                    style:family="graphic"
                />
                <style:style
                    style:name="Image"
                    style:family="graphic"
                    style:parent-style-name="Graphics"
                />
                <!-- Tabulars -->
                <style:style
                    style:name="Frame"
                    style:family="graphic"
                    >
                    <style:graphic-properties
                        text:anchor-type="paragraph"
                        svg:x="0in"
                        svg:y="0in"
                        fo:margin-top="0.0791in"
                        fo:margin-bottom="0.0791in"
                        style:wrap="parallel"
                        style:number-wrapped-paragraphs="no-limit"
                        style:wrap-contour="false"
                        style:vertical-pos="top"
                        style:vertical-rel="paragraph-content"
                        style:horizontal-pos="center"
                        style:horizontal-rel="paragraph-content"
                        fo:border="0.06pt
                        solid
                        #000000"
                    />
                </style:style>
                <style:style
                    style:name="Tabular-wrapper"
                    style:family="graphic"
                    style:parent-style-name="Frame"
                    >
                    <style:graphic-properties
                        style:vertical-pos="top"
                        style:vertical-rel="baseline"
                    />
                </style:style>
                <!-- Headings -->
                <!-- First, very generic heading styling -->
                <style:style
                    style:name="Heading"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-top="0.1665in"
                        fo:margin-bottom="0.0835in"
                    />
                    <style:text-properties
                        style:font-name="Main"
                        style:font-family-generic="roman"
                        style:font-pitch="variable"
                        fo:font-size="14pt"
                    />
                </style:style>
                <!-- Title of the worksheet -->
                <style:style
                    style:name="Title"
                    style:family="paragraph"
                    style:parent-style-name="Heading"
                    >
                    <style:paragraph-properties
                        fo:text-align="left"
                    />
                    <!-- 17pt is \large for base 12pt, matching LaTeX -->
                    <style:text-properties
                        fo:font-size="17pt"
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Header and Footer -->
                <!-- First, generic styling -->
                <style:style
                    style:name="Header_and_Footer"
                    style:display-name="Header and Footer"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties>
                        <!-- these tab stops allow for left|center|right header/footer -->
                        <style:tab-stops>
                            <style:tab-stop
                                style:position="3.4626in"
                                style:type="center"
                            />
                            <style:tab-stop
                                style:position="6.9252in"
                                style:type="right"
                            />
                        </style:tab-stops>
                    </style:paragraph-properties>
                </style:style>
                <!-- Headers in general -->
                <style:style
                    style:name="Header"
                    style:family="paragraph"
                    style:parent-style-name="Header_and_Footer"
                />
                <!-- Headers for page 1 -->
                <style:style
                    style:name="Header-first-page"
                    style:display-name="Header first page"
                    style:family="paragraph"
                    style:parent-style-name="Header"
                    >
                    <style:text-properties
                        fo:font-variant="small-caps"
                        fo:font-style="oblique"
                        fo:font-weight="normal"
                    />
                </style:style>
                <!-- Numbering -->
                <style:style
                    style:name="Exercise_Numbering"
                    style:display-name="Exercise Numbering"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <style:style
                    style:name="List_Numbering"
                    style:display-name="List Numbering"
                    style:family="text"
                />
                <style:style
                    style:name="Description_Numbering"
                    style:display-name="Description Numbering"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Styling the primary exercise numbering in a worksheet -->
                <text:list-style
                    style:name="Exercises"
                    >
                    <text:list-level-style-number
                        text:level="1"
                        text:style-name="Exercise_Numbering"
                        style:num-suffix="."
                        style:num-format="1"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="{$design-indent}{$design-unit}"
                                fo:text-indent="-{$design-indent}{$design-unit}"
                                fo:margin-left="{$design-indent}{$design-unit}"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                    <xsl:if test="exercise//ol">
                        <text:list-level-style-number
                            text:level="2"
                            text:style-name="List_Numbering"
                            style:num-prefix="("
                            style:num-suffix=")"
                            style:num-format="a"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{2 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{2 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-number>
                        <text:list-level-style-number
                            text:level="3"
                            text:style-name="List_Numbering"
                            style:num-suffix="."
                            style:num-format="i"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{3 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{3 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-number>
                        <text:list-level-style-number
                            text:level="4"
                            text:style-name="List_Numbering"
                            style:num-suffix="."
                            style:num-format="A"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{4 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{4 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-number>
                    </xsl:if>
                </text:list-style>
                <!-- Styling for a list in the introduction or conclusion -->
                <xsl:if test=".//ol[not(ancestor::exercise)]">
                    <text:list-style
                        style:name="List"
                        >
                        <text:list-level-style-number
                            text:level="1"
                            text:style-name="List_Numbering"
                            style:num-prefix="("
                            style:num-suffix=")"
                            style:num-format="a"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{$design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{2 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-number>
                        <text:list-level-style-number
                            text:level="2"
                            text:style-name="List_Numbering"
                            style:num-suffix="."
                            style:num-format="i"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{2 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{3 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-number>
                        <text:list-level-style-number
                            text:level="3"
                            text:style-name="List_Numbering"
                            style:num-suffix="."
                            style:num-format="A"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{3 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{4 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-number>
                    </text:list-style>
                </xsl:if>
                <!-- styling for an unordered list not in an exercise -->
                <xsl:if test=".//ul[not(ancestor::exercise)]">
                    <text:list-style
                        style:name="Unordered"
                        >
                        <text:list-level-style-bullet
                            text:level="1"
                            text:style-name="List_Numbering"
                            text:bullet-char="•"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{2 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{2 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                        <text:list-level-style-bullet
                            text:level="2"
                            text:style-name="List_Numbering"
                            text:bullet-char="◦"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{3 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{3 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                        <text:list-level-style-bullet
                            text:level="3"
                            text:style-name="List_Numbering"
                            text:bullet-char="■"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{4 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{4 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                        <text:list-level-style-bullet
                            text:level="4"
                            text:style-name="List_Numbering"
                            text:bullet-char="•"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{5 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{5 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                    </text:list-style>
                </xsl:if>
                <!-- styling for an unordered list not in an exercise -->
                <xsl:if test=".//ul[ancestor::exercise]">
                    <text:list-style
                        style:name="Exercises-unordered"
                        >
                        <text:list-level-style-bullet
                            text:level="2"
                            text:style-name="List_Numbering"
                            text:bullet-char="•"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{2 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{2 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                        <text:list-level-style-bullet
                            text:level="3"
                            text:style-name="List_Numbering"
                            text:bullet-char="◦"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{3 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{3 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                        <text:list-level-style-bullet
                            text:level="4"
                            text:style-name="List_Numbering"
                            text:bullet-char="■"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{4 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{4 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                        <text:list-level-style-bullet
                            text:level="5"
                            text:style-name="List_Numbering"
                            text:bullet-char="•"
                            >
                            <style:list-level-properties
                                text:list-level-position-and-space-mode="label-alignment"
                                >
                                <style:list-level-label-alignment
                                    text:label-followed-by="listtab"
                                    text:list-tab-stop-position="{5 * $design-indent}{$design-unit}"
                                    fo:text-indent="-{$design-indent}{$design-unit}"
                                    fo:margin-left="{5 * $design-indent}{$design-unit}"
                                />
                            </style:list-level-properties>
                        </text:list-level-style-bullet>
                    </text:list-style>
                </xsl:if>
                <!-- styling for various list levels with an author-defined label -->
                <xsl:if test=".//ol[@label]">
                    <xsl:variable name="ol-with-label" select=".//ol[@label]"/>
                    <xsl:for-each select="$ol-with-label">
                        <xsl:variable name="level">
                            <xsl:apply-templates select="." mode="list-level"/>
                        </xsl:variable>
                        <text:list-style>
                            <xsl:attribute name="style:name">
                                <xsl:apply-templates select="." mode="get-label"/>
                            </xsl:attribute>
                            <text:list-level-style-number
                                text:style-name="List_Numbering"
                                >
                                <xsl:attribute name="text:level">
                                    <xsl:value-of select="$level + 1"/>
                                </xsl:attribute>
                                <xsl:attribute name="style:num-prefix">
                                    <xsl:if test="contains(@label,'a')">
                                        <xsl:text>(</xsl:text>
                                    </xsl:if>
                                </xsl:attribute>
                                <xsl:attribute name="style:num-suffix">
                                    <xsl:choose>
                                        <xsl:when test="contains(@label,'a')">
                                            <xsl:text>)</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>.</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="style:num-format">
                                    <xsl:choose>
                                        <xsl:when test="contains(@label,'0')">
                                            <xsl:message>PTX:ERROR: .odt output format does not permit list numbering to begin with 0</xsl:message>
                                        </xsl:when>
                                        <xsl:when test="contains(@label,'1')">1</xsl:when>
                                        <xsl:when test="contains(@label,'a')">a</xsl:when>
                                        <xsl:when test="contains(@label,'A')">A</xsl:when>
                                        <xsl:when test="contains(@label,'i')">i</xsl:when>
                                        <xsl:when test="contains(@label,'I')">I</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:message>PTX:ERROR: ordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <style:list-level-properties
                                    text:list-level-position-and-space-mode="label-alignment"
                                    >
                                    <style:list-level-label-alignment
                                        text:label-followed-by="listtab"
                                        fo:text-indent="-{$design-indent}{$design-unit}"
                                        text:list-tab-stop-position="{$design-indent * ($level + 1)}{$design-unit}"
                                        fo:margin-left="{$design-indent * ($level + 2)}{$design-unit}"
                                    />
                                </style:list-level-properties>
                            </text:list-level-style-number>
                        </text:list-style>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test=".//ul[@label]">
                    <xsl:variable name="ul-with-label" select=".//ul[@label]"/>
                    <xsl:for-each select="$ul-with-label">
                        <xsl:variable name="level">
                            <xsl:apply-templates select="." mode="list-level"/>
                        </xsl:variable>
                        <text:list-style>
                            <xsl:attribute name="style:name">
                                <xsl:apply-templates select="." mode="get-label"/>
                            </xsl:attribute>
                            <text:list-level-style-bullet
                                text:style-name="List_Numbering"
                                >
                                <xsl:attribute name="text:level">
                                    <xsl:choose>
                                        <xsl:when test="ancestor::exercise">
                                            <xsl:value-of select="$level + 1"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$level"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="text:bullet-char">
                                    <xsl:choose>
                                        <xsl:when test="@label='disc'">•</xsl:when>
                                        <xsl:when test="@label='circle'">◦</xsl:when>
                                        <xsl:when test="@label='square'">■</xsl:when>
                                        <xsl:when test="@label=''"><xsl:call-template name="nbsp-character"/></xsl:when>
                                        <xsl:otherwise>
                                            <xsl:message>PTX:ERROR: unordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <style:list-level-properties
                                    text:list-level-position-and-space-mode="label-alignment"
                                    >
                                    <style:list-level-label-alignment
                                        text:label-followed-by="listtab"
                                        fo:text-indent="-{$design-indent}{$design-unit}"
                                        text:list-tab-stop-position="{$design-indent * ($level)}{$design-unit}"
                                        fo:margin-left="{$design-indent * ($level + 1)}{$design-unit}"
                                    />
                                </style:list-level-properties>
                            </text:list-level-style-bullet>
                        </text:list-style>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test=".//dl">
                    <xsl:variable name="dl" select=".//dl"/>
                    <xsl:for-each select="$dl">
                        <xsl:variable name="level">
                            <xsl:apply-templates select="." mode="list-level"/>
                        </xsl:variable>
                        <text:list-style>
                            <xsl:attribute name="style:name">
                                <xsl:apply-templates select="." mode="get-label"/>
                            </xsl:attribute>
                            <text:list-level-style-bullet
                                text:style-name="Description_Numbering"
                                >
                                <xsl:attribute name="text:level">
                                    <xsl:choose>
                                        <xsl:when test="ancestor::exercise">
                                            <xsl:value-of select="$level + 1"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$level"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="text:bullet-char">
                                    <xsl:call-template name="nbsp-character"/>
                                </xsl:attribute>
                                <style:list-level-properties
                                    text:list-level-position-and-space-mode="label-alignment"
                                    >
                                    <style:list-level-label-alignment
                                        text:label-followed-by="listtab"
                                        fo:text-indent="-{$design-indent}{$design-unit}"
                                        text:list-tab-stop-position="{$design-indent * ($level - 0.5)}{$design-unit}"
                                        fo:margin-left="{$design-indent * ($level)}{$design-unit}"
                                    />
                                </style:list-level-properties>
                            </text:list-level-style-bullet>
                        </text:list-style>
                    </xsl:for-each>
                </xsl:if>
            </office:styles>
            <office:automatic-styles>
                <style:page-layout style:name="Page">
                    <style:page-layout-properties
                        fo:page-width="{$design-page-width}{$design-unit}"
                        fo:page-height="{$design-page-height}{$design-unit}"
                        style:num-format="1"
                        style:print-orientation="portrait"
                        fo:margin-top="{$design-margin-top}{$design-unit}"
                        fo:margin-bottom="{$design-margin-bottom}{$design-unit}"
                        fo:margin-left="{$design-margin-left}{$design-unit}"
                        fo:margin-right="{$design-margin-right}{$design-unit}"
                        style:writing-mode="lr-tb"
                        >
                    </style:page-layout-properties>
                    <style:header-style>
                        <style:header-footer-properties
                            fo:min-height="0in"
                            fo:margin-left="0in"
                            fo:margin-right="0in"
                            fo:margin-bottom="0.1965in"
                        />
                    </style:header-style>
                    <style:footer-style/>
                </style:page-layout>
            </office:automatic-styles>
            <!-- Print header on first page, but move to a header-free page -->
            <office:master-styles>
                <style:master-page
                    style:name="Standard"
                    style:page-layout-name="Page"
                    style:next-style-name="Latter-page"
                    >
                    <style:header>
                        <text:p text:style-name="Header-first-page">
                            <xsl:apply-templates select="$document-root" mode="title-full" />
                            <text:tab/>
                            <xsl:apply-templates select="." mode="type-name" />
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="." mode="number" />
                            <text:tab/>
                            <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                        </text:p>
                    </style:header>
                </style:master-page>
                <style:master-page
                    style:name="Latter-page"
                    style:page-layout-name="Page"
                    style:next-style-name="Latter-page"
                />
            </office:master-styles>
        </office:document-styles>
    </exsl:document>
</xsl:template>

<!-- settings.xml -->
<!-- User settings for word processor application -->
<xsl:template match="worksheet" mode="settings">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'settings.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-settings office:version="1.3" />
    </exsl:document>
</xsl:template>

<!-- meta.xml -->
<!-- Metadata about this .odt file -->
<xsl:template match="worksheet" mode="meta">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'meta.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-meta office:version="1.3" />
    </exsl:document>
</xsl:template>

<!-- manifest.xml -->
<!-- A map to the component files -->
<xsl:template match="worksheet" mode="manifest">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'META-INF/manifest.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.3">
            <manifest:file-entry manifest:full-path="/" manifest:version="1.3" manifest:media-type="application/vnd.oasis.opendocument.text"/>
            <manifest:file-entry manifest:full-path="meta.xml" manifest:media-type="text/xml"/>
            <manifest:file-entry manifest:full-path="settings.xml" manifest:media-type="text/xml"/>
            <manifest:file-entry manifest:full-path="styles.xml" manifest:media-type="text/xml"/>
            <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
            <xsl:variable name="math" select=".//m|.//me|.//md"/>
            <xsl:for-each select="$math">
                <xsl:variable name="id">
                    <xsl:apply-templates select="." mode="visible-id"/>
                </xsl:variable>
                <manifest:file-entry manifest:full-path="Object-{$id}/" manifest:version="1.3" manifest:media-type="application/vnd.oasis.opendocument.formula"/>
                <manifest:file-entry manifest:full-path="Object-{$id}/content.xml" manifest:media-type="text/xml"/>
                <manifest:file-entry manifest:full-path="Object-{$id}/settings.xml" manifest:media-type="text/xml"/>
            </xsl:for-each>
            <xsl:variable name="images" select=".//image"/>
            <xsl:for-each select="$images">
                <xsl:variable name="id">
                    <xsl:apply-templates select="." mode="visible-id"/>
                </xsl:variable>
                <xsl:variable name="extension">
                    <xsl:apply-templates select="." mode="extension" />
                </xsl:variable>
                <xsl:variable name="type">
                    <xsl:apply-templates select="." mode="media-type"/>
                </xsl:variable>
                <manifest:file-entry manifest:full-path="images/{$id}.{$extension}" manifest:media-type="{$type}"/>
            </xsl:for-each>
        </manifest:manifest>
    </exsl:document>
</xsl:template>

<!-- content.xml -->
<!-- The actual content of the document -->
<xsl:template match="worksheet" mode="content">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'content.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-content
            office:version="1.3"
            xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            >
            <office:automatic-styles>
                <xsl:for-each select="//tabular">
                    <xsl:variable name="name">
                        <xsl:apply-templates select="." mode="visible-id"/>
                    </xsl:variable>
                    <xsl:variable name="width">
                        <xsl:apply-templates select="." mode="get-line-width"/>
                    </xsl:variable>
                    <style:style
                        style:name="{$name}"
                        style:family="table"
                        >
                        <style:table-properties
                            style:width="{$width}{$design-unit}"
                            table:align="margins"
                        />
                    </style:style>
                </xsl:for-each>
                <xsl:for-each select="//tabular/row/cell">
                    <xsl:variable name="col">
                        <xsl:apply-templates select="parent::row" mode="get-column-count">
                            <xsl:with-param name="up-to-cell" select="count(preceding-sibling::cell) + 1"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:variable name="row" select="count(parent::row/preceding-sibling::row) + 1"/>
                    <xsl:variable name="name">
                        <xsl:apply-templates select="ancestor::tabular" mode="visible-id"/>
                        <xsl:text>.</xsl:text>
                        <xsl:value-of select="substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ', $col, 1)"/>
                        <xsl:value-of select="$row"/>
                    </xsl:variable>
                    <!-- top border -->
                    <xsl:variable name="top">
                        <xsl:choose>
                            <!-- the first row of the table, so may have top border -->
                            <!-- http://ajaxandxml.blogspot.com/2006/11/xsl-detect-first-of-type-element-in.html -->
                            <xsl:when test="not(parent::row/preceding-sibling::row)">
                                <xsl:choose>
                                    <!-- col attribute first -->
                                    <xsl:when test="ancestor::tabular/col[$col]/@top">
                                        <xsl:value-of select="ancestor::tabular/col[$col]/@top" />
                                    </xsl:when>
                                    <!-- table attribute last -->
                                    <xsl:when test="ancestor::tabular/@top">
                                        <xsl:value-of select="ancestor::tabular/@top" />
                                    </xsl:when>
                                    <!-- default is none -->
                                    <xsl:otherwise>
                                        <xsl:text>none</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <!-- not the first cell of the row, so no top border -->
                            <xsl:otherwise>
                                <xsl:text>none</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- left border -->
                    <xsl:variable name="left">
                        <xsl:choose>
                            <!-- the first cell of the row, so may have left border -->
                            <xsl:when test="not(preceding-sibling::cell)">
                                <xsl:choose>
                                    <!-- row attribute first -->
                                    <xsl:when test="parent::row/@left">
                                        <xsl:value-of select="parent::row/@left" />
                                    </xsl:when>
                                    <!-- table attribute last -->
                                    <xsl:when test="ancestor::tabular/@left">
                                        <xsl:value-of select="ancestor::tabular/@left" />
                                    </xsl:when>
                                    <!-- default is none -->
                                    <xsl:otherwise>
                                        <xsl:text>none</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <!-- not the first cell of the row, so no left border -->
                            <xsl:otherwise>
                                <xsl:text>none</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- right border -->
                    <xsl:variable name="right">
                        <xsl:choose>
                            <!-- cell attribute first -->
                            <xsl:when test="@right">
                                <xsl:value-of select="@right" />
                            </xsl:when>
                            <!-- not available on rows, col attribute next -->
                            <xsl:when test="ancestor::tabular/col[$col]/@right">
                                <xsl:value-of select="ancestor::tabular/col[$col]/@right" />
                            </xsl:when>
                            <!-- table attribute last -->
                            <xsl:when test="ancestor::tabular/@right">
                                <xsl:value-of select="ancestor::tabular/@right" />
                            </xsl:when>
                            <!-- default is none -->
                            <xsl:otherwise>
                                <xsl:text>none</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- bottom border -->
                    <xsl:variable name="bottom">
                        <xsl:choose>
                            <!-- cell attribute first -->
                            <xsl:when test="@bottom">
                                <xsl:value-of select="@bottom" />
                            </xsl:when>
                            <!-- parent row attribute next -->
                            <xsl:when test="parent::row/@bottom">
                                <xsl:value-of select="parent::row/@bottom" />
                            </xsl:when>
                            <!-- not available on columns, table attribute last -->
                            <xsl:when test="ancestor::tabular/@bottom">
                                <xsl:value-of select="ancestor::tabular/@bottom" />
                            </xsl:when>
                            <!-- default is none -->
                            <xsl:otherwise>
                                <xsl:text>none</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- vertical alignment -->
                    <xsl:variable name="valignment">
                        <xsl:choose>
                            <!-- parent row attribute first -->
                            <xsl:when test="parent::row/@valign">
                                <xsl:value-of select="parent::row/@valign" />
                            </xsl:when>
                            <!-- table attribute last -->
                            <xsl:when test="ancestor::tabular/@valign">
                                <xsl:value-of select="ancestor::tabular/@valign" />
                            </xsl:when>
                            <!-- We default to "middle" to be consistent with LaTeX -->
                            <xsl:otherwise>
                                <xsl:text>middle</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="top-thickness">
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="$top"/>
                        </xsl:call-template>
                        <xsl:text>pt</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="left-thickness">
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="$left"/>
                        </xsl:call-template>
                        <xsl:text>pt</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="right-thickness">
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="$right"/>
                        </xsl:call-template>
                        <xsl:text>pt</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="bottom-thickness">
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="$bottom"/>
                        </xsl:call-template>
                        <xsl:text>pt</xsl:text>
                    </xsl:variable>
                    <style:style
                        style:name="{$name}"
                        style:family="table-cell"
                        >
                        <style:table-cell-properties
                            fo:border-top="{$top-thickness} solid #000000"
                            fo:border-left="{$left-thickness} solid #000000"
                            fo:border-right="{$right-thickness} solid #000000"
                            fo:border-bottom="{$bottom-thickness} solid #000000"
                            style:vertical-align="{$valignment}"
                        />
                    </style:style>
                </xsl:for-each>
            </office:automatic-styles>
            <office:body>
                <office:text>
                    <xsl:if test="title">
                        <text:h text:style-name="Title" text:outline-level="1">
                            <xsl:apply-templates select="." mode="title-full" />
                        </text:h>
                    </xsl:if>
                    <xsl:apply-templates select="introduction" />
                    <text:list text:style-name="Exercises">
                        <xsl:apply-templates select="exercise" />
                    </text:list>
                </office:text>
            </office:body>
        </office:document-content>
    </exsl:document>
</xsl:template>


</xsl:stylesheet>
