// [mhb] modified: Recode  // Author: mozers
var text_in = WScript.StdIn.ReadAll();

var WshShell = new ActiveXObject("WScript.Shell");
var fso = new ActiveXObject("Scripting.FileSystemObject");
var stream = new ActiveXObject("ADODB.Stream");


if (text_in.length<2) {
	WshShell.Popup("Please select some text in the editor! You must give me some text for conversion!");
	WScript.Quit(1);
}


var Args = WScript.Arguments;
if (Args.length < 2){
	WshShell.Popup("Usage: WSCRIPT myrecode.js input_encode output_encode\n==)Convert stdin text and write back to stdout");
	WScript.Quit(1);
}


var charset_in = Args(0);
var charset_out = Args(1);

var text_out=Recode(text_in, charset_in, charset_out);
if (Args.length==2) {
	WScript.Echo(text_out);
}
else {
	var filename = Args(2);
	var f1 = fso.CreateTextFile(filename, true);
	f1.Write(text_out);
	f1.Close()
}




function Recode(text_in, charset_in, charset_out){
	stream.Open();
	stream.Type = 2;
	stream.Charset = charset_out;
	stream.WriteText(text_in);
	stream.Flush();
	stream.Position = 0;
	stream.Charset = charset_in;
	var text_out = stream.ReadText(-1);
	stream.Close();
	return (text_out);
}

/*
function WriteFile( filename, text){
	var f = fso.OpenTextFile(filename, 2, true);
	f.Write(text);
	f.Close();
	return (true);
}

function ReadFile(filename) {
	var ForReading=1
	var f = fso.OpenTextFile(filename, ForReading)
	var s = f.ReadAll
	f.Close()
	return(s)
}
*/