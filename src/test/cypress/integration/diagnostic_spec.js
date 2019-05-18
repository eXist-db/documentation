/* global cy */
/// <reference types="cypress" />

// This is very slow and therefore skipped. Once diagnostics are re-written
// we might bring this back. In the meantime dead-links are tested via xQsuite
// see #

context.skip('Diagnostics', () => {
  before(() => {
    cy.visit('/diagnostics.html', { responseTimeout: 60000 })
  })
  it('should not find dead links', () => {
    cy.get('h1')
      .contains('Documentation link diagnostics')
      .parents('#main')
      .find('ul')
      .contains('advanced-installation.xml')
  })
})
