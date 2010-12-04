


function FileTransfer()
{
	this.nextTransferId = 0;
	this.downloadQueue = {};
	this.uploadQueue = {};
}


FileTransfer.prototype =
{
	// Upload
	upload:function(srcFilePath,postUrl,postData,succ,fail)
	{
		var reqId = "up" + this.nextTransferId++;
		var uploadReq = { succ : succ,
						  fail : fail,
						  srcFilePath : srcFilePath,
						  postUrl : postUrl,
						  postData : postData,
						  reqId : reqId};
		
		this.uploadQueue[reqId] = uploadReq;
		PhoneGap.exec("FileTransferCommand.upload",srcFilePath,postUrl,reqId,postData);
		return uploadReq;
	},
	
	_uploadComplete:function(reqId,response,bytesSent)
	{
		// todo: store more info about the upload locally
		var uploadReq = this.uploadQueue[reqId];
		uploadReq.succ(reqId,
					   unescape(response),
					   bytesSent,
					   uploadReq);
	},

	_uploadFailed:function(reqId,errMsg,response)
	{
		var uploadReq = this.uploadQueue[reqId];
		uploadReq.fail(errMsg,response,uploadReq);
		delete this.uploadQueue[reqId];
	},
	
	// Download
	download:function(srcUrl,destFilePath,succ,fail)
	{
		var reqId = "dwn" + this.nextTransferId++;
		var dlRequest = { succ : succ,
						  fail : fail,
						  reqId : reqId,
						  srcUrl : srcUrl,
						  destFilePath : destFilePath
		};
		this.downloadQueue[reqId] = dlRequest;
		PhoneGap.exec("FileTransferCommand.download",srcUrl,destFilePath,reqId);
		return dlRequest;
	},

	_downloadComplete:function(reqId,totalBytes)
	{
		var dlReq = this.downloadQueue[reqId];
		dlReq.totalBytes = totalBytes;
		dlReq.succ(reqId,totalBytes,dlReq);
		delete this.downloadQueue[reqId];
	},

	_downloadFailed:function(reqId,resultCode,response)
	{
		var dlReq = this.downloadQueue[reqId];
		dlReq.response = response;
		dlReq.resultCode = resultCode;
		dlReq.fail(reqId,resultCode,response,dlReq);
		delete this.downloadQueue[reqId];
	}
}

	
FileTransfer.installCommand = function()
{
	if (!navigator.plugins)
	{
		navigator.plugins = {};
	}
	navigator.plugins.fileTransfer = new FileTransfer();
}


PhoneGap.addConstructor(FileTransfer.installCommand);



