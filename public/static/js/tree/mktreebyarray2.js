// based on http://allabout.co.jp/internet/javascript/closeup/CU20060530A/index.htm

YAHOO.namespace('smc');
YAHOO.smc.tree = function(id) {

  this.tree = new YAHOO.widget.TreeView(id);
  
  YAHOO.smc.tree.prototype.mkTreeByArray = function (treeData,treeNode){
    if (!treeNode) {
      treeNode = this.tree.getRoot(); 
    }

    for (var i in treeData) {
      var tmpData = treeData[i];
      var key = tmpData[0];
      if (! key || key == "_open" || key == "_close" || key == "_load") {
      	continue;
      }

      var tmpNode = new YAHOO.widget.TextNode("" + key, treeNode, false);
      var nodeData = tmpData[1];
      if(typeof nodeData == "string") { 
        tmpNode.href= nodeData;
        tmpNode.target= "sample"; 
      } else if (typeof nodeData == "object") {
      	var nextTreeData = nodeData;
      	
        this.mkTreeByArray(nextTreeData, tmpNode); 
        switch (nextTreeData[0][0]) {
          case "_open": 
          	tmpNode.expand();
          	break;
          case "_close":
            tmpNode.collapse();
            break;
          case "_load": 
            YAHOO.smc.loadTreeData(this, tmpNode, tmpData);
            break;
          case "_exec":
          dafault:
            tmpNode.expand();
            break;
        }
      }
    }
    this.tree.draw();
  };
}

YAHOO.smc.loadTreeData = function(oj, tmpNode, treeDataFrg) {
  if (! YAHOO.util.Connect) {
    return;
  }
  
  var d = treeDataFrg[1][0][1];
  if (d) {
    tmpNode.method = d.method ? d.method : "GET";
    tmpNode.url = d.url ? d.url : "";
  }
  
  var f = function (node, onCompleteCallback) {
    tmpNode = new YAHOO.widget.Node("", tmpNode.pearent, false);
    var delay = YAHOO.smc.loadTreeData.delay;
    if (0 < delay) {
      setTimeout(onCompleteCallback, delay);
    } else {
      onCompleteCallback();
    }
  };
  tmpNode.setDynamicLoad(f);
      
  oj.tree.onExpand = function(node) {
	/*
    if (tmpNode.label != node.label) {
      return;
    }
    */
    if (node.children.length <= 0) {
      var opts = { 
        argument: {'node': node},
        scope: oj, 
        success: getResponse 
      };
      YAHOO.util.Connect.asyncRequest(node.method, node.url, opts, null);
    }
  };

  getResponse = function(oj) {
    data = eval(oj.responseText);
    this.mkTreeByArray(data, oj.argument.node);
  };
}

YAHOO.smc.loadTreeData.delay = 0;