// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "c47.h"
#include "c47-gtk.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

/*
*  Send printer output to emulated HP 82440B by Christoph Gieselink
*/

#include <glib.h>
#include <gio/gio.h>

#define UDPPORT 5025
#define UDPHOST "127.0.0.1"


//
//  Get print line delay
//
uint32_t getLineDelay() {
  return 0; // No delay on the simulator
}


//
//  Set print line delay
//
void setLineDelay(uint16_t delay) {
  return; // No delay on the simulator
}


//
// Send Byte to over IR
//
void sendByteIR( uint8_t c )
{
#if defined(INFRARED)
  GError * error = NULL;
  GSocket * socket;
  GSocketAddress *gsockAddr;
  gssize size_sent;
  gchar buffer[8];

  buffer[0] = c;
  printf("**[DL]** sendByteIR - start\n");fflush(stdout);
  //set_IO_annunciator();

  //Creates socket udp ipv4
  printf("**[DL]**  g_socket_new\n");fflush(stdout);
  socket = g_socket_new(G_SOCKET_FAMILY_IPV4,
                    G_SOCKET_TYPE_DATAGRAM,
                    G_SOCKET_PROTOCOL_UDP,
                    &error);
  g_assert(error == NULL);
  if (socket == NULL) {
    printf("ERROR\n");
    exit(1);
  }
  //sockaddr struct like
  printf("**[DL]**  gsockAddr\n");fflush(stdout);
  gsockAddr = G_SOCKET_ADDRESS(g_inet_socket_address_new(g_inet_address_new_from_string(UDPHOST), UDPPORT));

  if(gsockAddr == NULL){
    printf("Error socket\n");
    exit(1);
  }
  //
  printf("**[DL]**  g_socket_bind\n");fflush(stdout);
  if (g_socket_bind (socket, gsockAddr, TRUE, &error) == FALSE){
    printf("Error bind - domain: %d code: %d %s\n", error->domain, error->code, error->message);
    g_error_free(error);
    exit(1);
  }

  printf("**[DL]**  g_socket_send_to %c\n",(char) c);fflush(stdout);
  size_sent = g_socket_send_to(socket, gsockAddr, buffer /* (const gchar *) &c */, 1, NULL, &error);
  printf("**[DL]**  g_socket_send_to %lld byte\n", size_sent);fflush(stdout);
  if(error != NULL) {
    printf("Error g_socket_send_to - domain: %d code: %d %s\n", error->domain, error->code, error->message);
    g_error_free(error);
  }

  printf("**[DL]**  g_socket_close\n");fflush(stdout);
  g_socket_close(socket, NULL);
  //printf("Socket close %s\n", error->message);

  if(error != NULL) g_error_free(error);
  printf("**[DL]** sendByteIR - end\n");fflush(stdout);

#endif //INFRARED
}

void printer_advance_buf ( int what )
{
}

int printer_busy_for ( int what )
{
    return 0;
}

uint16_t printer_get_delay ()
{
    return 0;
}

uint16_t printer_set_delay (uint16_t val)
{
    return 0;
}

/*
uint8_t * lcd_line_addr ( int y)
{
    return 0;
}
*/