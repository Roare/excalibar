/*
 * Copyright 2002 the Excalibur contributors (http://excalibar.sourceforge.net/)
 *
 * Portions of this software are based on the work of Slicer/Hackersquest.
 * Those portions, Copyright 2001 Slicer/Hackersquest <slicer@hackersquest.org)
 * 
 * This file is part of Excalibur.
 *
 * Excalibur is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Excalibur is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <qstring.h>
#include <qregexp.h>
#include "exMessage.h"
#include "exPrefs.h"

exMessage::exMessage( QString* newMsg)
{ 
	this->Msg = *newMsg;
	this->MsgType = "Unknown";
	this->FormattedText = *newMsg;
}

void exMessage::parseMsg()
{
	QRegExp rxGuild( "\\[Guild\\] [A-Za-z]+\\:\\ ");
	QRegExp rxGroup( ".*\\[Party\\].*");
	QRegExp rxTell( ".*send[s]?\\,\\ \\\".*");
	QRegExp rxBCast( ".*\\*\\*.*\\*\\*$");
	QRegExp rxSay( ".*say[s]?\\,\\ \\\".*");
	int p;

	if( -1 != rxGuild.search( Msg))
		{
		this->MsgType = "Guild";
		this->Recvr   = "Guild";
		p = this->Msg.find( ":");
		this->Sender  = this->Msg.mid( 10, (p - 10));
		this->MsgText = this->Msg.mid( p + 2, this->Msg.length());
		this->FormattedText = this->Sender + ": " + this->MsgText;
		}
	else if( -1 != rxGroup.search( Msg))
		{
        this->MsgType = "Party";
        this->Recvr   = "Party";
        p = this->Msg.find( ":");
        this->Sender  = this->Msg.mid( 10, (p - 10));
        this->MsgText = this->Msg.mid( p + 2, this->Msg.length());
		this->FormattedText = this->Sender + ": " + this->MsgText;
		}
	else if( -1 != rxTell.search( Msg))
		{
		this->MsgType = "Tell";
        p = this->Msg.find( " ");
        this->Sender  = this->Msg.mid( 2, (p-2));
		this->Recvr   = this->Msg.mid( 
					this->Msg.findRev( " ")+1, this->Msg.length());
        this->MsgText = this->Msg.mid( 
					this->Msg.find( "\""), 
					this->Msg.findRev( "\"") - 
					      this->Msg.find( "\"") + 1);
		
		if( "You" != this->Sender) this->Recvr = "You";
		this->FormattedText = this->Sender;
		this->FormattedText += 
			this->Sender == "You" ? " tell " : " tells ";
		this->FormattedText += this->Recvr + " " + this->MsgText;
		}
    else if( -1 != rxBCast.search( Msg))
        {
        this->MsgType = "Broadcast";
        this->Recvr   = "Zone";
        p = this->Msg.find( ":");
        this->Sender  = this->Msg.mid( 2, (p-2));
        this->MsgText = this->Msg.mid( 
					this->Msg.find( "**"), this->Msg.length());
        
        this->FormattedText = this->Sender + " broadcasts: ";
        this->FormattedText += this->MsgText;
        }
    else if( -1 != rxSay.search( Msg))
        {
        this->MsgType = "Say";
        this->Recvr   = "Say";
        p = this->Msg.find( " ");
        this->Sender  = this->Msg.mid( 2, (p-2));
        this->MsgText = this->Msg.mid( 
					this->Msg.find( "\""), 
					this->Msg.findRev( "\"") - 
					      this->Msg.find( "\"") + 1);

        this->FormattedText = this->Sender;
        this->FormattedText += 
            this->Sender == "You" ? " say " : " sayss ";
        this->FormattedText += this->MsgText;
        }

	if( this->MsgText)
		printf("[%s] %s\n", 
				this->MsgType.ascii(), 
				this->FormattedText.ascii());
	else
		printf("[%s] %s\n", "Unknown", this->Msg.ascii());

}

int exMessage::getType()
{
	if( "Unknown" == MsgType) return 6;

	if( "Say" == MsgType) return 1;
	if( "Tell" == MsgType) return 2;
	if( "Party" == MsgType) return 3;
	if( "Guild" == MsgType) return 4;
	if( "Broadcast" == MsgType) return 5;

	return 0;
}		
