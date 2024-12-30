/* global cy */
/// <reference types="cypress" />

context('Documentation', () => {
    beforeEach(() => {
      cy.visit('xqsuite.xml')
    })
    describe('article should ...', () => {
      it('show heading', () => {
        cy.get('h1')
          .contains('XQSuite')
      })

      it('apply code highlighting', () => {
        cy.get('pre > .language-xml')
          .should('exist')
        cy.get('.hljs-tag')
          .should('exist')
      })

      it('correctly highlight xquery code', () => {
        cy.get('pre > .language-xquery')
          .should('exist')
        cy.get('.language-xquery > .hljs-meta')
          .should('exist')
      })
  })
})
  