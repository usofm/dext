{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2026-02-24                                                      }
{                                                                           }
{  Base interfaces and types for Dext.Collections.                          }
{                                                                           }
{***************************************************************************}
unit Dext.Collections.Base;

interface

type
  {$M+}
  IEnumerator<T> = interface
    function GetCurrent: T;
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  {$M+}
  IEnumerable<T> = interface
    function GetEnumerator: IEnumerator<T>;
  end;

  {$M+}
  IDextCollection = interface
    ['{A1B2C3D4-E5F6-4A5B-9C8D-0E1F2A3B4C5D}']
    function GetOwnsObjects: Boolean;
    procedure SetOwnsObjects(Value: Boolean);
    property OwnsObjects: Boolean read GetOwnsObjects write SetOwnsObjects;
  end;

  {$M+}
  IDextBufferProvider = interface
    ['{F4A7CB6D-1393-4B9A-B0F6-764E8B0E85D4}']
    function GetBuffer: Pointer;
    function GetSize: NativeInt;
    function GetElementSize: NativeInt;
  end;

implementation

end.
