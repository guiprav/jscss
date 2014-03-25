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
{
    function grammar_array_join (array)
    {
        return array.join('');
    }
}

start
  = StylesheetElement*

StylesheetElement
  = _:CSSRule
    {
        return _;
    }
 
  / _:UnparsedJavaScript
    {
        return _;
    }
 
CSSRule
  = __* _:_CSSRule __*
    {
        return _;
    }
 
_CSSRule
  = 'rule' __+ selector:CSSSelector __* '{' __* properties:CSSProperty* '}'
    {
        return { type: 'css', selector: selector, properties: properties };
    }
 
CSSSelector
  = _:_CSSSelector
    {
        return _.trim();
    }
 
_CSSSelector
  = head:CSSString tail:CSSSelector?
    {
        tail = tail || '';
        return head + tail;
    }
 
  / !NewLine !['"] !'{' head:. tail:CSSSelector?
    {
        tail = tail || '';
        return head + tail;
    }
 
CSSString
  = '"' _:CSSDoubleQuotedStringCharacter* '"'
    {
        return '"' + grammar_array_join(_) + '"';
    }
 
  / "'" _:CSSSingleQuotedStringCharacter* "'"
    {
        return "'" + grammar_array_join(_) + "'";
    }
 
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
 
  / '\\' _1:[0-9a-fA-F] _2:[0-9a-fA-F]?
    {
        return '\\' + _1 + _2;
    }
 
  / '\\' _:NewLine
    {
        return '\\' + _;
    }
 
  / !'\\' !['"] !NewLine _:.
    {
        return _;
    }
 
CSSProperty
  = _:_CSSProperty __*
    {
        return _;
    }
 
_CSSProperty
  = name:CSSPropertyName __* ':' __* value:CSSPropertyValue __* ';'
    {
        return { name: name, value: value };
    }
 
CSSPropertyName
  = _:[0-9a-zA-Z\-]+
    {
        return grammar_array_join(_);
    }
 
CSSPropertyValue
  = _:$CSSPropertyValuePart+
    {
        return _;
    }

CSSPropertyValuePart
  = UnparsedGenericBalancedPair
  / ![\[\](){}] !'/*' !'*/' !';' .
 
UnparsedJavaScript
  = _:UnparsedJavaScriptElement+
    {
        return { type: 'javascript', code: grammar_array_join(_).trim() };
    }
 
UnparsedJavaScriptElement
  = SingleLineComment
  / UnparsedGenericBalancedPair
  / UnparsedJavaScriptString
  / UnparsedJavaScriptLine
  / __
 
SingleLineComment
  = '//' _:(!NewLine _:. { return _ })*
    {
        return '//' + grammar_array_join(_);
    }
 
UnparsedJavaScriptLine
  = !('rule' __+) !BadJavaScript _:(!NewLine _:UnparsedJavaScriptCharacter { return _ })+
    {
        return grammar_array_join(_);
    }
 
BadJavaScript
  = (!NewLine !'do' !'else' !'try' UnparsedJavaScriptCharacter)+ '{'
 
UnparsedUnambiguousJavaScriptElement
  = SingleLineComment
  / UnparsedGenericBalancedPair
  / UnparsedJavaScriptString
  / UnparsedJavaScriptCharacter
 
UnparsedGenericBalancedPair
  = '{' _:UnparsedUnambiguousJavaScriptElement* '}'
    {
        return '{' + grammar_array_join(_) + '}';
    }
 
  / '[' _:UnparsedUnambiguousJavaScriptElement* ']'
    {
        return '[' + grammar_array_join(_) + ']';
    }
 
  / '(' _:UnparsedUnambiguousJavaScriptElement* ')'
    {
        return '(' + grammar_array_join(_) + ')';
    }
 
  / '/*' _:MultiLineCommentCharacter* '*/'
    {
        return '/*' + grammar_array_join(_) + '*/';
    }
 
MultiLineCommentCharacter
  = !'*/' _:.
    {
        return _;
    }
 
UnparsedJavaScriptString
  = '"' _:(JavaScriptStringCharacter / "'")* '"'
    {
        return '"' + grammar_array_join(_) + '"';
    }
 
  / "'" _:(JavaScriptStringCharacter / '"')* "'"
    {
        return "'" + grammar_array_join(_) + "'";
    }
 
JavaScriptStringCharacter
  = '\\' _:.
    {
        return _;
    }
 
  / !['"\r\n] .
 
UnparsedJavaScriptCharacter
  = !['"()\[\]{}] !'//' !'/*' !'*/' _:.
    {
        return _;
    }
 
_ = [ \t]
 
__ = _ / NewLine
 
NewLine = '\r\n' / [\r\n]
