module.exports = function(ast) {
	var code = 'var jscss$css = "";';
	ast.forEach (
		function(element) {
			switch(element.type) {
				case 'javascript':
					new Function(element.code);
					code += '\n' + element.code + ';'
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
											var compute_local_fn = new Function (
												'return ' + part.js + ';'
											);
											compute_locals +=
													'\nlocals.push ('
													+ '\n(' + compute_local_fn + '\n)()'
													+ '\n);';
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
					code +=
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
	code += '\nreturn jscss$css;';
	return code;
}
