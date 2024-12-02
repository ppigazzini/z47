// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file registerBrowser.h
 ***********************************************/
#if !defined(REGISTERBROWSER_H)
  #define REGISTERBROWSER_H

  #include <stdint.h>

  #if !defined(TESTSUITE_BUILD)
    /********************************************//**
     * \brief The register browser
     *
     * \param[in] unusedButMandatoryParameter uint16_t
     * \return void
     ***********************************************/
    void registerBrowser(uint16_t unusedButMandatoryParameter);
  #endif // !TESTSUITE_BUILD
#endif // !REGISTERBROWSER_H
