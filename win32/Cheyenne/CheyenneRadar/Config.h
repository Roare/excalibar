/******************************************************************************
Cheyenne: a real-time packet analyzer/sniffer for Dark Age of Camelot
Copyright (C) 2003, the Cheyenne Developers

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
******************************************************************************/
#pragma once

// we have to define NOMINMAX so that the stupid windows header files do 
// not make macros out of min and max :-/
#define NOMINMAX
//#include "..\Utils\CodeUtils.h" // for DECL_MEMBER
//#include "..\GLPPI\GLPPI.h" // for actor render prefs
class Config
{
public:
    Config();
    Config(const Config& s);
    ~Config();
    
    const Config& operator=(const Config& s);
    
    bool Load(const std::string& filename);
    bool Save(const std::string& filename)const;

protected:
private:
    void set(const Config& s);

    DECL_MEMBER(ActorRenderPrefs,PrefsSameRealm);
    DECL_MEMBER(ActorRenderPrefs,PrefsEnemyRealm);
    DECL_MEMBER(ActorRenderPrefs,PrefsMob);
    DECL_MEMBER(bool,RaisePriority);
    DECL_MEMBER(bool,UseZoneTextures);
    DECL_MEMBER(bool,UseVectorMaps);
}; // end Config
