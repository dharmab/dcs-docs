"""
Lua AST module for safe Lua code generation.

This module provides an AST-based approach to generating Lua code,
ensuring proper syntax and escaping by construction.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Union


class LuaNode(ABC):
    """Base class for all Lua AST nodes."""

    @abstractmethod
    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        """Convert this node to Lua source code."""
        pass


@dataclass
class LuaNil(LuaNode):
    """Represents Lua nil value."""

    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        return "nil"


@dataclass
class LuaBool(LuaNode):
    """Represents a Lua boolean value."""

    value: bool

    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        return "true" if self.value else "false"


@dataclass
class LuaNumber(LuaNode):
    """Represents a Lua number value."""

    value: Union[int, float]

    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        # Use integer format if it's a whole number
        if isinstance(self.value, float) and self.value.is_integer():
            return str(int(self.value))
        return str(self.value)


@dataclass
class LuaString(LuaNode):
    """Represents a Lua string value with proper escaping."""

    value: str

    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        # Escape special characters for Lua string
        escaped = self.value
        escaped = escaped.replace("\\", "\\\\")  # Backslash first
        escaped = escaped.replace('"', '\\"')  # Double quotes
        escaped = escaped.replace("\n", "\\n")  # Newlines
        escaped = escaped.replace("\r", "\\r")  # Carriage returns
        escaped = escaped.replace("\t", "\\t")  # Tabs
        escaped = escaped.replace("\0", "\\0")  # Null bytes
        return f'"{escaped}"'


@dataclass
class LuaTable(LuaNode):
    """
    Represents a Lua table.

    Supports both array-style (sequential integer keys) and dictionary-style entries.
    """

    entries: dict[Union[str, int], LuaNode] = field(default_factory=dict)

    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        if not self.entries:
            return "{\n" + (indent_str * indent) + "}"

        lines = ["{"]
        current_indent = indent_str * (indent + 1)
        closing_indent = indent_str * indent

        # Sort entries: integers first (in order), then strings (alphabetically)
        int_keys = sorted([k for k in self.entries.keys() if isinstance(k, int)])
        str_keys = sorted([k for k in self.entries.keys() if isinstance(k, str)])

        for key in int_keys + str_keys:
            value = self.entries[key]
            value_str = value.to_lua(indent + 1, indent_str)

            if isinstance(key, int):
                key_str = f"[{key}]"
            else:
                # Use simple key format if it's a valid identifier, otherwise use ["key"]
                if _is_valid_lua_identifier(key):
                    key_str = f'["{key}"]'
                else:
                    key_str = f'["{_escape_lua_string(key)}"]'

            # Add comment for table entries to match DCS style
            comment = ""
            if isinstance(value, LuaTable):
                if isinstance(key, int):
                    comment = f" -- end of [{key}]"
                else:
                    comment = f' -- end of ["{key}"]'

            lines.append(f"{current_indent}{key_str} = {value_str},{comment}")

        lines.append(closing_indent + "}")
        return "\n".join(lines)


@dataclass
class LuaAssignment(LuaNode):
    """Represents a Lua variable assignment: `name = value`."""

    name: str
    value: LuaNode

    def to_lua(self, indent: int = 0, indent_str: str = "    ") -> str:
        value_str = self.value.to_lua(indent, indent_str)

        # Add end comment for top-level table assignments
        comment = ""
        if isinstance(self.value, LuaTable):
            comment = f" -- end of {self.name}"

        return f"{self.name} =\n{value_str}{comment}\n"


def _is_valid_lua_identifier(s: str) -> bool:
    """Check if a string is a valid Lua identifier."""
    if not s:
        return False
    # Lua identifiers: start with letter or underscore, then letters/digits/underscores
    if not (s[0].isalpha() or s[0] == "_"):
        return False
    return all(c.isalnum() or c == "_" for c in s)


def _escape_lua_string(s: str) -> str:
    """Escape a string for use in Lua."""
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\n", "\\n")
    s = s.replace("\r", "\\r")
    s = s.replace("\t", "\\t")
    return s


# Type alias for values that can be converted to Lua nodes
LuaConvertible = Union[
    None, bool, int, float, str, dict, list, LuaNode
]


def to_lua_node(value: LuaConvertible) -> LuaNode:
    """
    Convert a Python value to a Lua AST node.

    Supports:
    - None -> LuaNil
    - bool -> LuaBool
    - int/float -> LuaNumber
    - str -> LuaString
    - dict -> LuaTable (with string keys)
    - list -> LuaTable (with 1-based integer keys)
    - LuaNode -> passed through unchanged
    """
    if value is None:
        return LuaNil()
    if isinstance(value, LuaNode):
        return value
    if isinstance(value, bool):
        return LuaBool(value)
    if isinstance(value, (int, float)):
        return LuaNumber(value)
    if isinstance(value, str):
        return LuaString(value)
    if isinstance(value, dict):
        table = LuaTable()
        for k, v in value.items():
            table.entries[k] = to_lua_node(v)
        return table
    if isinstance(value, list):
        table = LuaTable()
        for i, v in enumerate(value, start=1):  # Lua arrays are 1-indexed
            table.entries[i] = to_lua_node(v)
        return table

    raise TypeError(f"Cannot convert {type(value).__name__} to Lua node")


def generate_lua(name: str, value: LuaConvertible) -> str:
    """
    Generate a complete Lua assignment statement.

    Args:
        name: The variable name to