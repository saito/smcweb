// http://developer.yahoo.com/yui/examples/treeview/dynamic_tree.html
// http://allabout.co.jp/internet/javascript/closeup/CU20060530A/index.htm

YAHOO.namespace('jsontree');
YAHOO.jsontree.JsonTree = function(id) {
  this.id = id;
  this.tree = new YAHOO.widget.TreeView(id);
  this.node_count = 0;
};
  
YAHOO.jsontree.JsonTree.prototype.build = function(data, parentNode) {
  if (parentNode === undefined) {
    parentNode = this.tree.getRoot();
  }
  for (var i = 0; i < data.length; i++) {
    this.buildNode(data[i], parentNode);
  }
  this.tree.draw();
};

YAHOO.jsontree.JsonTree.prototype.buildNode = function(data, parentNode) {
  if (data.label === undefined) {
    return;
  }

  var param = {
    "id": "node" + this.id + "_" + this.node_count,
    "label": data.label
  };
  this.node_count++;
  
  var node = new YAHOO.widget.TextNode(param, parentNode, data.open);
  node.jsontree = data;
  node.jsontree.linked = false;

  if (data.command == "load") {
    this.initDynamicNode(data, node);
  } else if (data.command) {
    // TODO
  }

  if (data.href) {
    node.href = data.href;
    node.jsontree.linked = true;
  }
  if (data.target) {
    node.target = data.target;
  }

  if (data["."] !== undefined) {
    this.build(data["."], node);
  }
  
};

YAHOO.jsontree.JsonTree.prototype.initDynamicNode = function(data, node) {
  if (! YAHOO.util.Connect) {
  	alert("YAHOO.util.Connect required!");
    return;
  }

  var config = {
  	"url": data.src,
  	"method": data.method ? data.method : "GET"
  }
  node.jsontree.xhr_config = config;

  var jsontree = this;
  var loadNodeData = function(node, fnLoadComplete)  {
    var opts = { 
      success: function(oResponse) {
	    var data = eval("(" + oResponse.responseText + ")");
	    var arg = oResponse.argument;
		jsontree.build(data, arg.node);
		arg.fnLoadComplete();
      },
      failure: function(oResponse) { 
        // YAHOO.log("Failed to process XHR transaction.", "info", "example"); 
        oResponse.argument.fnLoadComplete(); 
      },
      argument: {
      	"node": node,
      	"fnLoadComplete": fnLoadComplete
      },
      timeout: 7000
    };

    var conf = node.jsontree.xhr_config;
    YAHOO.util.Connect.asyncRequest(conf.method, conf.url, opts, null);
  }
  node.setDynamicLoad(loadNodeData);
};
