module namespace docs="http://exist-db.org/apps/docs";

declare function docs:hello($node as node()*, $params as element(parameters)?, $model as item()*) {
    <span>Hello World!</span>
};