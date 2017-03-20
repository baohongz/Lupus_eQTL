#!/usr/bin/perl

################################################################################
#
# Generate interactive eQTL viewing html page
#
#################################################################################


use strict;
use Compress::Zlib;
use MIME::Base64;

my ($i, $line, $gzip, @items);
my ($fh, $SNP_alleles, $sample_annotation, $expression, $comstr);
my $MAXCOLUMN = 40;
my $KEEPCOLUMN = 20;
my $comheader = "";
my %geneDesc = {};

if (!defined $ARGV[0]) {
	print "Usage: $0 <expression file>\n";
	exit;
}

open(OUTPUT,">drug.html") || die $@;


open($fh,"Interaction_terms.txt") || die "Can't open Interaction_terms.txt file";
read $fh, $sample_annotation, -s $fh;
close($fh);

open($fh,"SNP_alleles.txt") || die "Can't open SNP_alleles.txt file";
read $fh, $SNP_alleles, -s $fh;
close($fh);


print OUTPUT <<HTMLBLOCK1;

<!DOCTYPE html>
<meta charset="utf-8">
<html>
<head>
<title> Lupus eQTL Report </title>
<link rel="stylesheet" type="text/css" href="package/SlickGrid/slick.grid.css"/>
<link rel="stylesheet" type="text/css" href="package/SlickGrid/examples/examples.css"/>
<link rel="stylesheet" type="text/css" href="package/SlickGrid/controls/slick.pager.css"/>
<link rel="stylesheet" type="text/css" href="package/SlickGrid/css/smoothness/jquery-ui-1.11.4.css"/>
<link rel="stylesheet" type="text/css" href="package/canvasXpress/css/canvasXpress.css"/>
<link rel="stylesheet" type="text/css" href="package/desktop/css/desktop.css" />

<script type="text/javascript" src="package/canvasXpress/js/canvasXpress.beautify.js"></script>

<script type="text/javascript" src="package/d3/d3.js" ></script>
<script type="text/javascript" src="package/jquery.js"></script>
<script type="text/javascript" src="package/jquery.ui.js"></script>
<script type="text/javascript" src="package/jquery.ui.sortable.js"></script>
<script type="text/javascript" src="package/pako_inflate.min.js"></script>
<script type="text/javascript" src="package/SlickGrid/divgrid.js"></script>
<script type="text/javascript" src="package/SlickGrid/lib/jquery.event.drag-2.2.js"></script>
<script type="text/javascript" src="package/SlickGrid/slick.core.js"></script>
<script type="text/javascript" src="package/SlickGrid/slick.grid.js"></script>
<script type="text/javascript" src="package/SlickGrid/slick.dataview.js"></script>
<script type="text/javascript" src="package/SlickGrid/controls/slick.pager.js"></script>

<style>
.ui-widget, .slick-pager, .tick {
  font-family: arial;
  font-size: 8pt;
}
#grid {
  bottom: 0;
  height: 300px; //Baohong: Modify to 200 for screenshot
}
#pager {
  bottom: 320px;
  height: 20px;
}
.slick-row:hover {
  font-weight: bold;
  color: #069;
}
</style>


</head>
<body>
<br>
<table border=0>
<tr><td nowrap>
Search: <input type="text" id="txtSearch" value="">
</td>
<td><b>Click on any column in a row will plot gene expression across conditions.</b></td>
<td><a href=index.html>Interferon eQTL</a></td>
<td><a href=Tcell.html>T cell eQTL</a></td>
</tr>
</table>

<div id="grid"></div>
<div id="pager"></div>

<p>

<div id="sample_annotation" style="display:none;">
$sample_annotation
</div>
<div id="SNP_alleles" style="display:none;">
$SNP_alleles
</div>

<div id="expression" style="display:none;">
HTMLBLOCK1

open($fh,$ARGV[0]) || die "Can't open $ARGV[0]\n";
$line = <$fh>;
@items = split(/\t/,$line);

if (@items <= $MAXCOLUMN) {
	for ($i=0; $i<@items; $i++) {
		print OUTPUT "$items[$i]";
		if ($i<@items-1) { print OUTPUT "\t"; }
	}
	while ($line = <$fh>) {
		@items = split(/\t/,$line);
		$items[0] =~ s/\.\d+$//g;
		for ($i=0; $i<@items; $i++) {
			print OUTPUT "$items[$i]";
			if ($i<@items-1) { print OUTPUT "\t"; }
		}
	}
} else {
	@items = split(/\t/,$line,$KEEPCOLUMN+1);
	for ($i=0; $i<$KEEPCOLUMN; $i++) {
		print OUTPUT "$items[$i]\t";
	}
	print OUTPUT "comstr\n";
	$comheader = $items[$KEEPCOLUMN];

	while ($line = <$fh>) {
		@items = split(/\t/,$line,$KEEPCOLUMN+1);
		$items[0] =~ s/\.\d+$//g;
		for ($i=0; $i<$KEEPCOLUMN; $i++) {
			print OUTPUT "$items[$i]\t";
		}
	
		$items[$KEEPCOLUMN] =~ s/\s+$//g;
		$gzip = Compress::Zlib::memGzip( $items[$KEEPCOLUMN] );
		$comstr = encode_base64($gzip);
		$comstr =~ s/\n//g;
		print OUTPUT "$comstr\n";
	}
}
close($fh);

# get Genotyping data
open($fh,"Genotyping.new.txt") || die $@;
$line = <$fh>;
print OUTPUT "</div><div id=\"snpheader\" style=\"display:none;\">\n$line</div><div id=\"Genotyping\" style=\"display:none;\">\n";
print OUTPUT "SNP\tsnpheader\n";
while ($line = <$fh>) {
	@items = split(/\t/, $line, 2);
	$items[1] =~ s/\s+$//g;
	$gzip = Compress::Zlib::memGzip( $items[1] );
	$comstr = encode_base64($gzip);
	$comstr =~ s/\n//g;
	print OUTPUT "$items[0]\t$comstr\n";
}
close($fh);

print OUTPUT <<HTMLBLOCK2;
</div>

<div id="comheader" style="display:none;">
$comheader</div>

<script type="text/javascript">

// load tsv file and create the chart

var anno = d3.tsv.parse(d3.select('#sample_annotation').text().replace(/^\\s+|\\s+\$/g, ''));
var SNP_alleles = d3.tsv.parse(d3.select('#SNP_alleles').text().replace(/^\\s+|\\s+\$/g, ''));
var Genotyping = d3.tsv.parse(d3.select('#Genotyping').text().replace(/^\\s+|\\s+\$/g, ''));
var comheader = d3.select('#comheader').text().replace(/^\\s+|\\s+\$/g, '');
var snpheader = d3.select('#snpheader').text().replace(/^\\s+|\\s+\$/g, '');


console.log(JSON.stringify(anno));

//alert(Object.keys(anno[0]));
//alert(anno[0]["sample_id"]);

// Index main tables to make query fast
var SNP_allelesIndex = {};
for (var i=0; i < SNP_alleles.length; i++) {
	SNP_allelesIndex[SNP_alleles[i].SNP] = i;
}
var GenotypingIndex = {};
for (var i=0; i < Genotyping.length; i++) {
	GenotypingIndex[Genotyping[i].SNP] = i;
}

// console.log(Genotyping[GenotypingIndex["rs3094315"]]["snpheader"]);

var features = Object.keys(anno[0]);
var sampleIndex = {};

for (var i = 0; i < anno.length; i++) {
	sampleIndex[anno[i].sample_id] = i;
}

var expression = d3.select('#expression').text().replace(/^\\s+|\\s+\$/g, '');
var data = d3.tsv.parse(expression);

// slickgrid needs each data element to have an id
data.forEach(function(d, i) {
	d.id = d.id || i;
});


// setting up grid
var column_keys = d3.keys(data[0]).filter(function(i) { return i != "comstr" });
var columns = column_keys.map(function(key, i) {
	return {
		id: key,
		name: key,
		field: key,
		sortable: true
	}
});

// SlickGrid
var options = {
	enableCellNavigation: true,
	multiColumnSort: false
};

var afterRenderObject1 = [];
var afterRenderObject = [];
var canvasid;
var canvasid1;
var dataView = new Slick.Data.DataView();
var grid = new Slick.Grid("#grid", dataView, columns, options);
var pager = new Slick.Controls.Pager(dataView, grid, \$("#pager"));

// wire up model events to drive the grid
dataView.onRowCountChanged.subscribe(function(e, args) {
	grid.updateRowCount();
	grid.render();
});

dataView.onRowsChanged.subscribe(function(e, args) {
	grid.invalidateRows(args.rows);
	grid.render();
});


// column sorting
var sortcol = column_keys[0];
var sortdir = 1;

function comparer(a, b) {

    // Baohong Zhang: fix to sort numberic values
    if (\$.isNumeric(a[sortcol]) && \$.isNumeric(b[sortcol])) {
        a[sortcol] = parseFloat(a[sortcol], 10);
        b[sortcol] = parseFloat(b[sortcol], 10);
    }

	var x = a[sortcol],
		y = b[sortcol];
	return (x == y ? 0 : (x > y ? 1 : -1));
}

// click header to sort grid column
grid.onSort.subscribe(function(e, args) {
	sortdir = args.sortAsc ? 1 : -1;
	sortcol = args.sortCol.field;

	dataView.sort(comparer, args.sortAsc);
});

// highlight row in chart
grid.onMouseEnter.subscribe(function(e, args) {
	var i = grid.getCellFromEvent(e).row;
});

grid.onMouseLeave.subscribe(function(e, args) {});

grid.onClick.subscribe(function(e, args) {


	//alert(features[1]);
	//alert(anno[sampleIndex["SRR821282"]][features[1]]);
	//alert(grid.getDataItem(args.row)["id"]);

	var winid = dataView.getIdxById(grid.getDataItem(args.row)["id"]);
	canvasid = "canvas_" + winid;
	canvasid1 = "canvas1_" + winid;
	var gene;
	var SNPs = {};
	var Alleles;
	var headers, strData, charData, binData, pakoData, vals;
	var SNP_Illumina_ID = grid.getDataItem(args.row)["SNP_Illumina_ID"]
	var SNP_rsID = grid.getDataItem(args.row)["SNP_rsID"]

	if (grid.getDataItem(args.row)["Gene_name"].length > 1) {
		gene = grid.getDataItem(args.row)["Gene_name"];
		Alleles = SNP_alleles[SNP_allelesIndex[SNP_Illumina_ID]];
	}


	headers = snpheader.split("\\t");
	// Decode base64 (convert ascii to binary)
	strData  = atob(Genotyping[GenotypingIndex[SNP_Illumina_ID]]["snpheader"]);

	// Convert binary string to character-number array
	charData    = strData.split('').map(function(x){return x.charCodeAt(0);});
	
	// Turn number array into byte-array
	binData     = new Uint8Array(charData);
	
	// Pako magic
	pakoData     = pako.inflate(binData);
	
	// Convert gunzipped byteArray back to ascii string:
	strData     = String.fromCharCode.apply(null, new Uint16Array(pakoData)).replace(/^\\s+|\\s+\$/g, '');

	var vals = strData.split("\\t");
	
	for (var i=0;i<headers.length;i++) {
		SNPs[headers[i]] = vals[i];
	}

//console.log(JSON.stringify(SNPs));

	var plotDiv =
		'<div id="window_' + winid + '"' + ' class="abs window">' +
		'  <div class="abs window_inner">' +
		'	<div class="window_top">' +
		'	  <span class="float_right">' +
		'		<a href="#" class="window_resize"></a>' +
		'		<a href="#" class="window_close"></a>' +
		'	  </span>' +
		'	</div>' +
		'	<div class="abs window_content"><table border=0 padding=0><tr>' +
		'		<td><canvas id=' + canvasid1 + ' width=600 height=400></canvas></td>' +
		'		<td><canvas id=' + canvasid + ' width=600 height=400></canvas><td></tr></table>' +
		'	</div>' +
		'  </div>' +
		'</div>';

	\$('body').append(plotDiv);

	var myrow = winid;
//	var plotdata = JSON.parse(JSON.stringify(data[myrow])));
    var plotdata = new Object();
    for (var i=0;i<anno.length;i++) {
        var sample = anno[i][features[0]];
        if (data[myrow][sample] != null) {
            plotdata[sample] = data[myrow][sample];
        }
    }
	
	if (comheader.length > 1) {
		headers = comheader.split("\\t");
		// Decode base64 (convert ascii to binary)
		strData  = atob(data[myrow]["comstr"]);

		// Convert binary string to character-number array
		charData    = strData.split('').map(function(x){return x.charCodeAt(0);});
		
		// Turn number array into byte-array
		binData     = new Uint8Array(charData);
		
		// Pako magic
		pakoData     = pako.inflate(binData);
		
		// Convert gunzipped byteArray back to ascii string:
		strData     = String.fromCharCode.apply(null, new Uint16Array(pakoData)).replace(/^\\s+|\\s+\$/g, '');
	
		var vals = strData.split("\\t");
		
		for (var i=0;i<headers.length;i++) {
			plotdata[headers[i]] = vals[i];
		}
	}

		 
	var tobeSorted = [];
	for (var i=0; i<anno.length; i++) {
 		var dataRow = {};	
		for (var f=0; f<features.length; f++) {
			dataRow[features[f]] = anno[i][features[f]];
		}
		var s = anno[i][features[0]]; // sample
		dataRow["SNP"] = SNPs[s];
		dataRow["exp"] = plotdata[s];
		tobeSorted.push(dataRow);
	}

	var sorted = helper.arr.multisort(tobeSorted, ['SNP','Drug'], ['ASC','DESC']);

	for (var i=0; i < sorted.length; i++) {
		if (sorted[i]["SNP"].length == 1) {
			var g = "Geno_"+sorted[i]["SNP"]
			sorted[i]["SNP"] = Alleles[g];
		}
	}


	delete Alleles["SNP"];
	var keys = Object.keys(Alleles);
	var Alleles_value = keys.map(function(v) { return Alleles[v]; });
// console.log(JSON.stringify(sorted));


	valStr = '';
	data4plot = '{ "x" : {';

	if (features[features.length - 1] != "SNP") {
		features.push("SNP");
	}

	for (var f = 1; f < features.length; f++) {
		data4plot += '"' + features[f] + '":[';

		var valStr = '';
		for (var i = 0; i < sorted.length; i++) {
			valStr += '"' + sorted[i][features[f]] + '",';
		}
		valStr = valStr.slice(0, -1);
		data4plot += valStr + "],";
	}

	data4plot = data4plot.slice(0, -1);
	data4plot += '}, "y":{ "vars":["Expression"], "smps":[';

	valStr = '';
	for (var i = 0; i < sorted.length; i++) {
		valStr += '"' + sorted[i][features[0]] + '",';
	}

	valStr = valStr.slice(0, -1);
	data4plot += valStr + '], "data":[[';

	valStr = '';
	for (var i = 0; i < sorted.length; i++) {
        var valadd = parseFloat(sorted[i]["exp"]);
        valStr += valadd.toFixed(3) + ',';
	}
	valStr = valStr.slice(0, -1);
	data4plot += valStr + ']] } }';

//console.log(data4plot);

	params =
		'		  {' +
		'		   "axisTitleFontStyle": "italic",' +
		'		   "axisTickScaleFontFactor": 1.5,' +
		'		   "axisTitleScaleFontFactor": 2.4,' +
		'		   "smpLabelScaleFontFactor": 1.5,' +
		'		   "smpTitleScaleFontFactor": 2.0,' +
		'		   "legendScaleFontFactor": 1.8,' +
		'			"graphOrientation": "vertical",' +
		'			"showLegend": true,' +
        '           "xAxisTitle": "log2(CPM+1)",' +
		'			"xAxis2Show": false,' +
		'		   "graphType": "Boxplot",' +
		'		   "jitter": true,' +
        '          "canvasBox": true,' +
        '          "printType": "window",' +
        '          "layoutBoxLabelColors" : ["lightgrey", "lightgrey", "lightgrey", "lightgrey"],' +
		'			"title": "Gene expression of ' + grid.getDataItem(args.row)["Gene_name"] + '",' +
		'			"smpTitle": "' + SNP_rsID + '",' +
		'		   "showBoxplotOriginalData": true' +
		'		  }';

	var storeRenderObject = afterRenderObject;
	afterRenderObject = [];
	var alreadySet = {};
	var renderObject = [];

	while(storeRenderObject.length > 0) {
    	var item = storeRenderObject.pop();
		if (alreadySet[item[0]] == null || item[0] == "changeAttribute") {
			alreadySet[item[0]] = 1;
			renderObject.push(item);
		}
	}
//	afterRenderObject = renderObject.reverse();

	if (afterRenderObject.length < 1) {
		afterRenderObject.push(["updateDataFilter",[true],{"toDoFilter":{"sample":{"Drug":{"exact":["Exposed","Unexposed"]},"SNP":{"exact":Alleles_value}}}}]);
		afterRenderObject.push(["changeAttribute",["colorBy","SNP"]]);
		afterRenderObject.push(["groupSamples",[["Drug","SNP"]]]);
		afterRenderObject.push(["sortSamplesByCategory",[["Drug"]],{"sortDir":"descending"}]);
		afterRenderObject.push(["toggleAttribute", [ "boxplotConnect" ] ]);
		afterRenderObject.push(["setDimensions",[410,372]]);

	}


    var cxBoxplot = new CanvasXpress({
        renderTo: canvasid,
        data: JSON.parse(data4plot),
        config: JSON.parse(params),
        afterRender: afterRenderObject
    });


	storeRenderObject = afterRenderObject1;
	afterRenderObject1 = [];
	alreadySet = {};
	renderObject = [];

	while(storeRenderObject.length > 0) {
    	var item = storeRenderObject.pop();
		if (alreadySet[item[0]] == null || item[0] == "changeAttribute") {
			alreadySet[item[0]] = 1;
			renderObject.push(item);
		}
	}
//	afterRenderObject1 = renderObject.reverse();

	if (afterRenderObject1.length < 1) {
		afterRenderObject1.push(["changeAttribute",["colorBy","Drug"]]);
		afterRenderObject1.push(["groupSamples",[["SNP","Drug"]]]);
		afterRenderObject1.push(["updateDataFilter",[true],{"toDoFilter":{"sample":{"Drug":{"exact":["Exposed","Unexposed"]},"SNP":{"exact":Alleles_value}}}}]);
		afterRenderObject1.push(["setDimensions",[410,372]]);
	}


    var cxBoxplot1 = new CanvasXpress({
        renderTo: canvasid1,
        data: JSON.parse(data4plot),
        config: JSON.parse(params),
        afterRender: afterRenderObject1
    });




    var y = "#window_" + winid;
    //
    //        // Bring window to front.
    JQD.util.window_flat();
	\$(y).width(800);
    \$(y).addClass('window_stack').show();

    cxBoxplot.afterRender();
    cxBoxplot1.afterRender();

	//
	//// args.row - row of the clicked cell
	//// args.cell - column of the clicked cell

});


var searchString = "";

function myFilter(data, args) {
	if (args.searchString != "" &&
		data[columns[0].name].toUpperCase().indexOf(args.searchString.toUpperCase()) == -1 &&
		data[columns[1].name].toUpperCase().indexOf(args.searchString.toUpperCase()) == -1 &&
		data[columns[2].name].toUpperCase().indexOf(args.searchString.toUpperCase()) == -1 &&
		data[columns[3].name].toUpperCase().indexOf(args.searchString.toUpperCase()) == -1 &&
		data[columns[4].name].toUpperCase().indexOf(args.searchString.toUpperCase()) == -1)
	{
		return false;
	}
	return true;
}

\$("#txtSearch").keyup(function(e) {
	Slick.GlobalEditorLock.cancelCurrentEdit();

	// clear on Esc
	if (e.which == 27) {
		this.value = "";
	}

	searchString = this.value;
	updateFilter();
});

function updateFilter() {
	dataView.setFilterArgs({
		searchString: searchString
	});
	dataView.refresh();
}

function gridUpdate(data) {
	dataView.beginUpdate();
	dataView.setItems(data);

	dataView.setFilterArgs({
		searchString: searchString
	});

	dataView.setFilter(myFilter);

	dataView.endUpdate();
};

// fill grid with data
gridUpdate(data);


if( typeof helper == 'undefined' ) {
  var helper = { } ;
}

helper.arr = {
    multisort: function(arr, columns, order_by) {
        if(typeof columns == 'undefined') {
            columns = []
            for(x=0;x<arr[0].length;x++) {
                columns.push(x);
            }
        }

        if(typeof order_by == 'undefined') {
            order_by = []
            for(x=0;x<arr[0].length;x++) {
                order_by.push('ASC');
            }
        }

        function multisort_recursive(a,b,columns,order_by,index) {  
            var direction = order_by[index] == 'DESC' ? 1 : 0;

            var is_numeric = !isNaN(+a[columns[index]] - +b[columns[index]]);


            var x = is_numeric ? +a[columns[index]] : a[columns[index]].toLowerCase();
            var y = is_numeric ? +b[columns[index]] : b[columns[index]].toLowerCase();



            if(x < y) {
                    return direction == 0 ? -1 : 1;
            }

            if(x == y)  {               
                return columns.length-1 > index ? multisort_recursive(a,b,columns,order_by,index+1) : 0;
            }

            return direction == 0 ? 1 : -1;
        }

        return arr.sort(function (a,b) {
            return multisort_recursive(a,b,columns,order_by,0);
        });
    }
};

var JQD = (function(\$, window, document, undefined) {
	// Expose innards of JQD.
	return {
		go: function() {
			for (var i in JQD.init) {
				JQD.init[i]();
			}
		},
		init: {
			frame_breaker: function() {
				if (window.location !== window.top.location) {
					window.top.location = window.location;
				}
			},
			//
			// Initialize the desktop.
			//
			desktop: function() {
				// Alias to document.
				var d = \$(document);



				// Focus active window.
				d.on('mousedown', 'div.window', function() {
					// Bring window to front.
					JQD.util.window_flat();
					\$(this).addClass('window_stack');
				});

				// Make windows draggable.
				d.on('mouseenter', 'div.window', function() {
					\$(this).off('mouseenter').draggable({
						cancel: 'a',
						drag: function(event, ui) {
							if (ui.position.top < 0) {
								ui.position.top = 0;
							}

						},

						// Baohong: don't contain in parent window
						//		  containment: 'parent',
						handle: 'div.window_top'
					}).resizable({
						//			containment: 'parent',
						minWidth: 400,
						minHeight: 200
					});
				});


				// Maximize or restore the window.
				d.on('click', 'a.window_resize', function() {
					JQD.util.window_resize(this);
				});

				// Close the window.
				d.on('click', 'a.window_close', function() {

// console.log(canvasid);

var cx = CanvasXpress.getObject(canvasid);

if (cx != null) {
	afterRenderObject = cx.getStack();
//	console.log(afterRenderObject);
}

cx = CanvasXpress.getObject(canvasid1);
if (cx != null) {
	afterRenderObject1 = cx.getStack();
}


					\$(this).closest('div.window').hide();
					\$(this).closest('div.window').remove();
				});
			},
		},

		util: {
			//
			// Clear active states, hide menus.
			//
			clear_active: function() {
				\$('a.active, tr.active').removeClass('active');
				\$('ul.menu').hide();
			},
			//
			// Zero out window z-index.
			//
			window_flat: function() {
				\$('div.window').removeClass('window_stack');
			},
			//
			// Resize modal window.
			//
			window_resize: function(el) {
				// Nearest parent window.
				var win = \$(el).closest('div.window');

				// Is it maximized already?
				if (win.hasClass('window_full')) {
					// Restore window position.
					win.removeClass('window_full').css({
						'top': win.attr('data-t'),
						'left': win.attr('data-l'),
						'right': win.attr('data-r'),
						'bottom': win.attr('data-b'),
						'width': win.attr('data-w'),
						'height': win.attr('data-h')
					});
				} else {
					win.attr({
						// Save window position.
						'data-t': win.css('top'),
						'data-l': win.css('left'),
						'data-r': win.css('right'),
						'data-b': win.css('bottom'),
						'data-w': win.css('width'),
						'data-h': win.css('height')
					}).addClass('window_full').css({
						// Maximize dimensions.
						'top': '0',
						'left': '0',
						'right': '0',
						'bottom': '0',
						'width': '100%',
						'height': '100%'
					});
				}

				// Bring window to front.
				JQD.util.window_flat();
				win.addClass('window_stack');
			}
		}
	};
	// Pass in jQuery.
})(jQuery, this, this.document);

jQuery(document).ready(function() {
	JQD.go();
});
</script>
<br>
<b>Note:</b>"NA"s in the table indicate that the Gene-SNP pair did not pass the threshold of at least 2 individuals with minor allele in each group and therefore wasn't tested for an interaction or the particular environmental factor of interest (drug, IFN, or Tcell).
<br><br>
Please use Chrome or Firefox for browsering. It is fully functional under Chrome v57.0.2987.98, Firefox v52.0, and Safari v9.1.2. You can also download the <a href=https://github.com/baohongz/Lupus_eQTL/blob/gh-pages/Lupus_eQTL.zip>Lupus_eQTL.zip</a> file to your local PC, unzip it and start exploring by opening index.html in Chrome or Firefox even without WIFI.

</body>
</html>
HTMLBLOCK2

close(OUTPUT);
