#!/usr/bin/env python
# IFaceTableGen.py - regenerate the IFaceTable.cxx from the Scintilla.iface
# interface definition file.  Based on Scintilla's HFacer.py.
# The header files are copied to a temporary file apart from the section between a //++Autogenerated
# comment and a //--Autogenerated comment which is generated by the printHFile and printLexHFile
# functions. After the temporary file is created, it is copied back to the original file name.

import sys
import os

srcRoot = "../.."

sys.path.append(srcRoot + "/scintilla/include")

import Face

def Contains(s,sub):
	return s.find(sub) != -1

def StartsWith(s, prefix):
	return s.find(prefix) == 0

def CommentString(prop):
	if prop and prop["Comment"]:
		return " -- " + " ".join(prop["Comment"])
	return ""

def GetScriptableInterface(f):
	"""Returns a tuple of (constants, functions, properties)
constants - a sorted list of (name, features) tuples, including all
	constants except for SCLEX_ constants which are presumed not used by
	scripts.  The SCI_ constants for functions are omitted, since they
	can be derived, but the SCI_ constants for properties are included
	since they cannot be derived from the property names.
functions - a sorted list of (name, features) tuples, for the features
	that should be exposed to script as functions.  This includes all
	'fun' functions; it is up to the program to decide if a given
	function cannot be scripted.  It is also up to the caller to
	export the SCI_ constants for functions.
properties - a sorted list of (name, property), where property is a
	dictionary containing these keys: "GetterValue", "SetterValue",
	"PropertyType", "IndexParamType", "IndexParamName", "GetterName",
	"SetterName", "GetterComment", "SetterComment", and "Category".
	If the property is read-only, SetterValue will be 0, and the other
	Setter attribtes will be None.  Likewise for write-only properties,
	GetterValue will be 0 etc.  If the getter and/or setter are not
	compatible with one another, or with our interpretation of how
	properties work, then the functions are instead added to the
	functions list.  It is still up to the language binding to decide
	whether the property can / should be exposed to script."""

	constants = [] # returned as a sorted list
	functions = {} # returned as a sorted list of items
	properties = {} # returned as a sorted list of items

	for name in f.order:
		features = f.features[name]
		if features["Category"] != "Deprecated":
			if features["FeatureType"] == "val":
				constants.append( (name, features) )
			elif features["FeatureType"] in ["fun","get","set"]:
				if features["FeatureType"] == "get":
					propname = name.replace("Get", "", 1)
					properties[propname] = (name, properties.get(propname,(None,None))[1])

				elif features["FeatureType"] == "set":
					propname = name.replace("Set", "", 1)
					properties[propname] = (properties.get(propname,(None,None))[0], name)

				else:
					functions[name] = features

	propertiesCopy = properties.copy()
	for propname, (getterName, setterName) in propertiesCopy.items():
		getter = getterName and f.features[getterName]
		setter = setterName and f.features[setterName]

		getterValue, getterIndex, getterIndexName, getterType = 0, None, None, None
		setterValue, setterIndex, setterIndexName, setterType = 0, None, None, None
		propType, propIndex, propIndexName = None, None, None

		isok = (getterName or setterName) and not (getter is setter)

		if isok and getter:
			if getter['Param2Type'] == 'stringresult':
				getterType = getter['Param2Type']
			else:
				getterType = getter['ReturnType']
			getterValue = getter['Value']
			getterIndex = getter['Param1Type'] or 'void'
			getterIndexName = getter['Param1Name']

			isok = ((getter['Param2Type'] or 'void') == 'void') or (getterType == 'stringresult')

		if isok and setter:
			setterValue = setter['Value']
			setterType = setter['Param1Type'] or 'void'
			setterIndex = 'void'
			if (setter['Param2Type'] or 'void') != 'void':
				setterIndex = setterType
				setterIndexName = setter['Param1Name']
				setterType = setter['Param2Type']

			isok = (setter['ReturnType'] == 'void') or (setter['ReturnType'] == 'int' and setterType=='string')

		if isok and getter and setter:
			isok = ((getterType == setterType) or (getterType == 'stringresult' and setterType == 'string')) and (getterIndex == setterIndex)

		propType = getterType or setterType
		propIndex = getterIndex or setterIndex
		propIndexName = getterIndexName or setterIndexName

		if isok:
			# do the types appear to be useable?  THIS IS OVERRIDDEN BELOW
			isok = (propType in ('int', 'position', 'colour', 'bool', 'string', 'stringresult')
				and propIndex in ('void','int','position','string','bool'))

			# getters on string properties follow a different protocol with this signature
			# for a string getter and setter:
			#   get int funcname(void,stringresult)
			#   set void funcname(void,string)
			#
			# For an indexed string getter and setter, the indexer goes in
			# wparam and must not be called 'int length', since 'int length'
			# has special meaning.

			# A bool indexer has a special meaning.  It means "if the script
			# assigns the language's nil value to the property, call the
			# setter with args (0,0); otherwise call it with (1, value)."
			#
			# Although there are no getters indexed by bool, I suggest the
			# following protocol:  If getter(1,0) returns 0, return nil to
			# the script.  Otherwise return getter(0,0).


		if isok:
			properties[propname] = {
				"GetterValue"    : getterValue,
				"SetterValue"    : setterValue,
				"PropertyType"   : propType,
				"IndexParamType" : propIndex,
				"IndexParamName" : propIndexName,
				# The rest of this metadata is added to help generate documentation
				"Category"       : (getter or setter)["Category"],
				"GetterName"     : getterName,
				"SetterName"     : setterName,
				"GetterComment"  : CommentString(getter),
				"SetterComment"  : CommentString(setter)
			}
			#~ print(properties[propname])

			# If it is exposed as a property, the constant name is not picked up implicitly
			# (because the name is different) but its constant should still be exposed.
			if getter:
				constants.append( ("SCI_" + getterName.upper(), getter))
			if setter:
				constants.append( ("SCI_" + setterName.upper(), setter))
		else:
			# Cannot parse as scriptable property (e.g. not symmetrical), so export as functions
			del(properties[propname])
			if getter:
				functions[getterName] = getter
			if setter:
				functions[setterName] = setter

	funclist = list(functions.items())
	funclist.sort()

	proplist = list(properties.items())
	proplist.sort()

	constants.sort()

	return (constants, funclist, proplist)


def printIFaceTableCXXFile(faceAndIDs, out):
	f, ids = faceAndIDs
	(constants, functions, properties) = GetScriptableInterface(f)
	constants.extend(ids)
	constants.sort()

	out.write("\nstatic IFaceConstant ifaceConstants[] = {")

	if constants:
		first = 1
		for name, features in constants:
			if first: first = 0
			else: out.write(",")
			val = features["Value"]
			if int(val, base=0) >= 0x8000000:
				val = "static_cast<int>(" + val + ")"
			out.write('\n\t{"%s",%s}' % (name, val))

		out.write("\n};\n")
	else:
		out.write('{"",0}};\n')

	# Write an array of function descriptions.  This can be
	# used as a sort of compiled typelib.

	out.write("\nstatic IFaceFunction ifaceFunctions[] = {")
	if functions:
		first = 1
		for name, features in functions:
			if first: first = 0
			else: out.write(",")

			paramTypes = [
				features["Param1Type"] or "void",
				features["Param2Type"] or "void"
			]

			returnType = features["ReturnType"]

			# Fix-up: if a param is an int named length, change to iface_type_length.
			if features["Param1Type"] == "int" and features["Param1Name"] == "length":
				paramTypes[0] = "length"

			if features["Param2Type"] == "int" and features["Param2Name"] == "length":
				paramTypes[1] = "length"

			out.write('\n\t{"%s", %s, iface_%s, {iface_%s, iface_%s}}' % (
				name, features["Value"], returnType, paramTypes[0], paramTypes[1]
			))

		out.write("\n};\n")
	else:
		out.write('{"",0,iface_void,{iface_void,iface_void}} };\n')


	out.write("\nstatic IFaceProperty ifaceProperties[] = {")
	if properties:
		first = 1
		for propname, property in properties:
			if first: first = 0
			else: out.write(",")
			out.write('\n\t{"%s", %s, %s, iface_%s, iface_%s}' % (
				propname,
				property["GetterValue"],
				property["SetterValue"],
				property["PropertyType"], property["IndexParamType"]
			))

		out.write("\n};\n")
	else:
		out.write('{"", 0, iface_void, iface_void} };\n')

	out.write("\nenum {\n")
	out.write("\tifaceFunctionCount = %d,\n" % len(functions))
	out.write("\tifaceConstantCount = %d,\n" % len(constants))
	out.write("\tifacePropertyCount = %d\n" % len(properties))
	out.write("};\n\n")

def convertStringResult(s):
	if s == "stringresult":
		return "string"
	else:
		return s

def idsFromDocumentation(filename):
	""" Read the Scintilla documentation and return a list of all the features 
	in the same order as they are explained in the documentation.
	Also include the previous header with each feature. """
	idsInOrder = []
	segment = ""
	with open(filename) as f:
		for l in f:
			if "<h2" in l:
				segment = l.split(">")[1].split("<")[0]
			if 'id="SCI_' in l:
				idFeature = l.split('"')[1]
				#~ print(idFeature)
				idsInOrder.append([segment, idFeature])
	return idsInOrder

nonScriptableTypes = ["cells", "textrange", "findtext", "formatrange"]

def printIFaceTableHTMLFile(faceAndIDs, out):
	f, ids, idsInOrder = faceAndIDs
	(constants, functions, properties) = GetScriptableInterface(f)
	explanations = {}
	for name, features in functions:
		featureDefineName = "SCI_" + name.upper()
		explanation = ""
		href = ""
		hrefEnd = ""
		href = "<a href='http://www.scintilla.org/ScintillaDoc.html#" + featureDefineName + "'>"
		hrefEnd = "</a>"
		
		if features['Param1Type'] in nonScriptableTypes or features['Param2Type'] in nonScriptableTypes:
			#~ print(name, features)
			continue

		parameters = ""
		stringresult = ""
		if features['Param2Type'] == "stringresult":
			stringresult = "string "
			if features['Param1Name'] and features['Param1Name'] != "length":
				parameters += features['Param1Type'] + " " + features['Param1Name'] 
		else:
			if features['Param1Name']:
				parameters += features['Param1Type'] + " " + features['Param1Name'] 
				if features['Param1Name'] == "length" and features['Param2Type'] == "string":
					# special case removal
					parameters = ""
			if features['Param2Name']:
				if parameters:
					parameters += ", "
				parameters += features['Param2Type'] + " " + features['Param2Name'] 
			
		returnType = stringresult
		if not returnType and features["ReturnType"] != "void":
			returnType = convertStringResult(features["ReturnType"]) + " "

		explanation += '%seditor:%s%s%s(%s)' % (
			returnType,
			href,
			name, 
			hrefEnd,
			parameters
		)
		if features["Comment"]:
			explanation += '<span class="comment">%s</span>' % CommentString(features)

		explanations[featureDefineName] = explanation

	for propname, property in properties:
		functionName = property['SetterName'] or property['GetterName']
		featureDefineName = "SCI_" + functionName.upper()
		explanation = ""
		href = "<a href='http://www.scintilla.org/ScintillaDoc.html#" + featureDefineName + "'>"
		hrefEnd = "</a>"

		direction = ""
		if not property['SetterName']:
			direction = " read-only"
		if not property['GetterName']:
			direction = " write-only"
		indexExpression = ""
		if property["IndexParamType"] != "void":
			indexExpression = "[" + property["IndexParamType"] + " " + property["IndexParamName"] + "]"

		explanation += '%s editor.%s%s%s%s%s' % (
			convertStringResult(property["PropertyType"]),
			href,
			propname, 
			hrefEnd,
			indexExpression,
			direction
		)
		if property["SetterComment"]:
			explanation += '<span class="comment">%s</span>' % property["SetterComment"]
		explanations[featureDefineName] = explanation

	lastSegment = ""
	for segment, featureId in idsInOrder:
		if featureId in explanations:
			if segment != lastSegment:
				out.write('\t<h2>')
				out.write(segment)
				out.write('</h2>\n')
				lastSegment = segment
			out.write('\t<p>')
			out.write(explanations[featureId])
			out.write('</p>\n')
	out.write("\n")

def CopyWithInsertion(input, output, genfn, definition):
	copying = 1
	for line in input.readlines():
		if copying:
			output.write(line)
		if Contains(line, "//++Autogenerated") or Contains(line, "<!-- <Autogenerated> -->"):
			copying = 0
			genfn(definition, output)
		if Contains(line, "//--Autogenerated") or Contains(line, "<!-- </Autogenerated> -->"):
			copying = 1
			output.write(line)

def contents(filename):
	f = open(filename)
	t = f.read()
	f.close()
	return t

def Regenerate(filename, genfn, definition):
	inText = contents(filename)
	tempname = "IFaceTableGen.tmp"
	out = open(tempname,"w")
	hfile = open(filename)
	CopyWithInsertion(hfile, out, genfn, definition)
	out.close()
	hfile.close()
	outText = contents(tempname)
	if inText == outText:
		os.unlink(tempname)
	else:
		os.unlink(filename)
		os.rename(tempname, filename)

def ReadMenuIDs(filename):
	ids = []
	f = open(filename)
	try:
		for l in f:
			if l.startswith("#define"):
				#~ print l
				try:
					d, name, number = l.split()
					if name.startswith("IDM_"):
						ids.append((name, {"Value":number}))
				except ValueError:
					# No value present
					pass
	finally:
		f.close()
	return ids

f = Face.Face()
f.ReadFromFile(srcRoot + "/scintilla/include/Scintilla.iface")
menuIDs  = ReadMenuIDs(srcRoot + "/scite/src/SciTE.h")
idsInOrder = idsFromDocumentation(srcRoot + "/scintilla/doc/ScintillaDoc.html")
Regenerate(srcRoot + "/scite/src/IFaceTable.cxx", printIFaceTableCXXFile, [f, menuIDs])
Regenerate(srcRoot + "/scite/doc/PaneAPI.html", printIFaceTableHTMLFile, [f, menuIDs, idsInOrder])
