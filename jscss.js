#!/usr/bin/env node
/*
    Copyright (c) 2013, 2014 Guilherme Vieira (super.driver.512@gmail.com)

    This file is part of JSCSS.

    JSCSS is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    JSCSS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with JSCSS. If not, see <http://www.gnu.org/licenses/>.
*/
var util = require('util');
var fs = require('fs');
var peg = require('pegjs');
var input_file = process.argv[2];
if(!input_file) {
	console.error("Missing input file.");
	console.log("Usage: node jscss.js input-file");
	process.exit(-1);
}
var input_data = fs.readFileSync(input_file, 'utf8');
var grammar_source = fs.readFileSync(__dirname + '/jscss.pegjs', 'utf8');
var jscss;
try {
	jscss = peg.buildParser(grammar_source);
}
catch(err) {
	console.error("Could not build parser:", err.message);
	process.exit(-1);
}
var parse_results;
try {
	parse_results = jscss.parse(input_data);
}
catch(err) {
	if(err.name !== 'SyntaxError') {
		throw err;
	}
	console.error("Line", err.line + ", column", err.column + ":", err.message);
	process.exit(-1);
}
console.log("JSCSS parse tree:");
console.log (
	util.inspect (
		jscss.parse(input_data), {
			depth: null
		}
	)
);
var final_code = 'var jscss$css = "";';
parse_results.forEach (
	function(element) {
		switch(element.type) {
			case 'javascript':
				final_code += '\n' + element.code + ';'
				break;
			case 'css':
				var compute_locals = 'var locals = [];';
				var next_local_id = 0;
				var rule_body_parts = [];
				var rule_body;
				element.properties.forEach (
					function(property) {
						var value;
						if(typeof(property.value) === 'string') {
							value = JSON.stringify(property.value);
						}
						else {
							value = property.value.map (
								function(part) {
									if(typeof(part) === 'string') {
										return JSON.stringify(part);
									}
									else {
										compute_locals +=
												'\nlocals.push(eval('
												+ JSON.stringify(part.js)
												+ '));';
										return 'locals[' + (next_local_id++) + ']';
									}
								}
							);
						}
						rule_body_parts = rule_body_parts.concat (
							JSON.stringify('\n\t' + property.name + ': ')
							, value
							, '";"'
						);
					}
				);
				rule_body = rule_body_parts.join('\n+ ');
				final_code +=
						'\n(function() {'
						+ '\n' + compute_locals
						+ '\njscss$css += '
						+ JSON.stringify(element.selector)
						+ '\n+ ' + JSON.stringify('\n{')
						+ '\n+ ' + rule_body
						+ '\n+ ' + JSON.stringify('\n}')
						+ '\n})();';
				break;
			default:
				throw new Error("Unknown element type: '" + element.type + "'.");
		}
	}
);
final_code += '\nreturn jscss$css;';
console.log();
console.log("Final JavaScript function body:");
console.log(final_code);
console.log();
console.log("Final CSS:");
console.log((new Function(final_code))());
