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
start
  = StylesheetElement*

StylesheetElement
  = CSSRule
  / UnparsedJavaScript
 
CSSRule
  = __* _:_CSSRule __*
    {
        return _;
    }
 
_CSSRule
  = 'rule' __+ selector:CSSSelector __* '{' __* properties:CSSProperty* '}'
    {
        return {
            type: 'css'
            , selector: selector
            , properties: properties
            , line: line()
            , column: column()
        };
    }
 
CSSSelector
  = _:_CSSSelector
    {
        return _.trim();
    }
 
_CSSSelector
  = $(CSSString CSSSelector?)
  / $(!['"] !'{' . CSSSelector?)
 
CSSString
  = $('"' CSSDoubleQuotedStringCharacter* '"')
  / $("'" CSSSingleQuotedStringCharacter* "'")
 
CSSDoubleQuotedStringCharacter
  = "'"
  / CSSGeneralStringCharacter
 
CSSSingleQuotedStringCharacter
  = '"'
  / CSSGeneralStringCharacter
 
CSSGeneralStringCharacter
  = '\\"'
  / "\\'"
  / '\\\\'
  / $('\\' [0-9a-fA-F] [0-9a-fA-F]?)
  / $('\\' NewLine)
  / '\\#'
  / $(!'\\' !['"] !NewLine .)
 
CSSProperty
  = _:_CSSProperty __*
    {
        return _;
    }
 
_CSSProperty
  = name:CSSPropertyName __* ':' __* value:CSSPropertyValue __* ';'
    {
        return { name: name, value: value, line: line(), column: column() };
    }
 
CSSPropertyName
  = $([0-9a-zA-Z\-]+)

CSSPropertyValue
  = $(CSSPropertyValuePart+)

CSSPropertyValuePart
  = $(CSSPropertyValueBalancedPairPart)
  / $(CSSString)
  / $((!['"[({})\]] !'/*' !'*/' !';' .)+)

CSSPropertyValueBalancedPairPart
  = '[' CSSPropertyValueSemiColonAllowedPart* ']'
  / '(' CSSPropertyValueSemiColonAllowedPart* ')'
  / '{' CSSPropertyValueSemiColonAllowedPart* '}'

CSSPropertyValueSemiColonAllowedPart
  = CSSPropertyValueBalancedPairPart
  / $(CSSString)
  / $((!['"[({})\]] !'/*' !'*/' .)+)

JavaScriptInterpolations
  = JavaScriptInterpolationPart*

JavaScriptInterpolationPart
  = _:(
        !'#{'
		_:(
            '\\#{' / $('\\' .) / .
        )
        {
			var dreaded_string = '#' + String.fromCharCode(123);
			if(_ === '\\' + dreaded_string) {
				return dreaded_string;
			}
			else {
				return _;
			}
		}
	)+
    {
        return _.join('');
    }

  / !'\\' '#{' _:UnparsedJavaScript '}' { return _ }

UnparsedJavaScript
  = _:$(UnparsedJavaScriptElement+)
    {
        return { type: 'javascript', code: _.trim(), line: line(), column: column() };
    }
 
UnparsedJavaScriptElement
  = SingleLineComment
  / UnparsedGenericBalancedPair
  / UnparsedJavaScriptString
  / UnparsedJavaScriptLine
  / __
 
SingleLineComment
  = $('//' (!NewLine .)*)
 
UnparsedJavaScriptLine
  = $(!('rule' __+) (!NewLine UnparsedJavaScriptCharacter)+)
 
UnparsedUnambiguousJavaScriptElement
  = SingleLineComment
  / UnparsedGenericBalancedPair
  / UnparsedJavaScriptString
  / UnparsedJavaScriptCharacter
 
UnparsedGenericBalancedPair
  = $('{' UnparsedUnambiguousJavaScriptElement* '}')
  / $('[' UnparsedUnambiguousJavaScriptElement* ']')
  / $('(' UnparsedUnambiguousJavaScriptElement* ')')
  / $('/*' MultiLineCommentCharacter* '*/')
 
MultiLineCommentCharacter
  = $(!'*/' .)
 
UnparsedJavaScriptString
  = $('"' (JavaScriptStringCharacter / "'")* '"')
  / $("'" (JavaScriptStringCharacter / '"')* "'")
 
JavaScriptStringCharacter
  = $('\\' .)
  / $(!['"\r\n] .)
 
UnparsedJavaScriptCharacter
  = $(!['"()\[\]{}] !'//' !'/*' !'*/' .)
 
_ = [ \t]
 
__ = _ / NewLine
 
NewLine = '\r\n' / [\r\n]
