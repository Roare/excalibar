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
#ifndef GLOBAL_H
#define GLOBAL_H
#pragma once

#ifdef MAIN_FUNCTION
    #define EXTERN 
#else
    #define EXTERN extern
#endif

#define DECL_MEMBER(type,name) \
    public: \
    inline const type & Get##name(void)const{return(m_##name);}; \
    inline const type & Set##name(const type & val){m_##name=val;return(m_##name);}; \
    private: \
    inline type & Modify##name(void){return(m_##name);}; \
    type m_##name;

#define MEMBER_ASSIGN(name) \
    Set##name(s.Get##name());

#include <winsock2.h>
#include <windows.h>
#include <iostream>

#include "times.h" // include for time definitions
#include "config.h" // include for config class

// the clock
EXTERN CheyenneClock Clock;

// the config
EXTERN ShareNetConfig Config;

// helper operators
inline std::ostream& operator<< (std::ostream& str,const struct in_addr& a)
{
    str << unsigned int(a.S_un.S_un_b.s_b1) << "."
        << unsigned int(a.S_un.S_un_b.s_b2) << "."
        << unsigned int(a.S_un.S_un_b.s_b3) << "."
        << unsigned int(a.S_un.S_un_b.s_b4);
        
    return(str);
} // end operator<< (std::ostream& str,const struct in_addr& a)
inline std::ostream& operator<< (std::ostream& str,const SOCKADDR_IN& a)
{
    str << a.sin_addr << ":" << ntohs(a.sin_port);
    return(str);
} // end operator<< (std::ostream& str,const SOCKADDR_IN& a)

#define TYPED_CONTAINING_RECORD(address,type,field) \
    (type*)CONTAINING_RECORD(address,type,field)
#endif // GLOBAL_H